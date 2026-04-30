import streamlit as st
import numpy as np
import tensorflow as tf
import io
import wave
from streamlit_mic_recorder import mic_recorder

# --- UI Configuration ---
st.set_page_config(page_title="ResoNET: AI Sound Recognition", page_icon="🎯", layout="wide")

# Custom CSS for a sleek look
st.markdown("""
    <style>
    .main { background-color: #f5f7f9; }
    .stMetric { background-color: #ffffff; padding: 15px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
    .match-box { padding: 20px; border-radius: 10px; text-align: center; font-weight: bold; font-size: 24px; }
    </style>
    """, unsafe_allow_html=True)

st.title("🎯 ResoNET: Metric Learning Sound Identifier")
st.markdown("---")

# --- 1. Load Model ---
@st.cache_resource
def load_model():
    try:
        # Assumes assets/models/resonet_model.tflite exists
        interpreter = tf.lite.Interpreter(model_path="resonet_model.tflite")
        interpreter.allocate_tensors()
        return interpreter
    except Exception as e:
        st.error(f"Model Load Error: {e}")
        return None

interpreter = load_model()

# --- 2. Inference Engine ---
def get_embedding(audio_bytes):
    if not audio_bytes or not interpreter: return None
    try:
        audio_file = io.BytesIO(audio_bytes)
        with wave.open(audio_file, 'rb') as wav_file:
            frames = wav_file.readframes(wav_file.getparams().nframes)
            samples = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0

        # Match the 5-second requirement (80,000 samples)
        input_size = 80000 
        samples = samples[:input_size] if len(samples) > input_size else np.pad(samples, (0, max(0, input_size - len(samples))))
        
        input_data = np.expand_dims(samples, axis=0)
        input_details = interpreter.get_input_details()
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        return interpreter.get_tensor(interpreter.get_output_details()[0]['index']).flatten()
    except Exception as e:
        st.error(f"Inference Logic Error: {e}")
        return None

# --- 3. Layout ---
if 'ref_emb' not in st.session_state: st.session_state.ref_emb = None

left_col, right_col = st.columns([1, 1], gap="large")

with left_col:
    st.subheader("🛠️ Step 1: Enrollment")
    st.info("Record a 5-second sample to set as the reference sound.")
    enroll_rec = mic_recorder(start_prompt="🔴 Start Recording", stop_prompt="⏹️ Stop", key='enroll', format="wav")
    
    if enroll_rec:
        with st.spinner("Processing Reference..."):
            st.session_state.ref_emb = get_embedding(enroll_rec['bytes'])
            if st.session_state.ref_emb is not None:
                st.success("Reference Sound Captured Successfully!")

with right_col:
    st.subheader("🔍 Step 2: Live Monitoring")
    if st.session_state.ref_emb is None:
        st.warning("Awaiting Reference Enrollment...")
    else:
        test_rec = mic_recorder(start_prompt="🎤 Check Live Sound", stop_prompt="⏹️ Stop", key='test', format="wav")
        
        if test_rec:
            with st.spinner("Comparing Vectors..."):
                test_emb = get_embedding(test_rec['bytes'])
                if test_emb is not None:
                    # Cosine Similarity
                    sim = np.dot(st.session_state.ref_emb, test_emb) / (np.linalg.norm(st.session_state.ref_emb) * np.linalg.norm(test_emb) + 1e-9)
                    
                    # Visual Feedback
                    st.metric(label="Similarity Score", value=f"{sim:.4f}")
                    st.progress(float(np.clip(sim, 0.0, 1.0)))

                    if sim > 0.85:
                        st.markdown('<div class="match-box" style="background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb;">✅ MATCH DETECTED!</div>', unsafe_allow_html=True)
                        st.balloons()
                    else:
                        st.markdown('<div class="match-box" style="background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb;">❌ NO MATCH</div>', unsafe_allow_html=True)

st.markdown("---")
with st.expander("📝 Project Specifications"):
    st.write("**Model:** ResoNET TFLite v1.0")
    st.write("**Input:** 80,000 Samples (5.0s @ 16kHz)")
    st.write("**Architecture:** Metric Learning (Embedding Comparison)")
