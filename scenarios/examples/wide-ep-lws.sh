# WIDE EP WELL LIT PATH
# Based on https://github.com/llm-d-incubation/llm-d-infra/tree/main/quickstart/examples/wide-ep-lws
# Removed pod monitoring; can be added using LLMDBENCH_VLLM_MODELSERVICE_EXTRA_POD_CONFIG
# Removed extra volumes metrics-volume and torch-compile-volume; they are not needed for this model and tested hardware.
# Use LLMDBENCH_VLLM_MODELSERVICE_EXTRA_VOLUME_MOUNTS and LLMDBENCH_VLLM_MODELSERVICE_EXTRA_VOLUMES to add them if needed.

# IMPORTANT NOTE
# All parameters not defined here or exported externally will be the default values found in setup/env.sh
# Many commonly defined values were left blank (default) so that this scenario is applicable to as many environments as possible.

# Model parameters
# export LLMDBENCH_DEPLOY_MODEL_LIST="Qwen/Qwen3-0.6B"
# export LLMDBENCH_DEPLOY_MODEL_LIST="facebook/opt-125m"
# export LLMDBENCH_DEPLOY_MODEL_LIST="meta-llama/Llama-3.1-8B-Instruct"
export LLMDBENCH_DEPLOY_MODEL_LIST=deepseek-ai/DeepSeek-V2-Lite
export LLMDBENCH_VLLM_COMMON_PVC_MODEL_CACHE_SIZE=30Gi

# Workload parameters
export LLMDBENCH_HARNESS_EXPERIMENT_PROFILE=random_concurrent.yaml
export LLMDBENCH_HARNESS_NAME=vllm-benchmark

# Routing configuration (via gaie)
export LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_TAG=v0.2.1
export LLMDBENCH_VLLM_MODELSERVICE_GAIE_PLUGINS_CONFIGFILE=pd-config.yaml
export LLMDBENCH_VLLM_MODELSERVICE_GAIE_CUSTOM_PLUGINS=$(mktemp)
cat << EOF > ${LLMDBENCH_VLLM_MODELSERVICE_GAIE_CUSTOM_PLUGINS}
pd-config.yaml: |
  # ALWAYS DO PD IN THIS EXAMPLE (THRESHOLD 0)
  apiVersion: inference.networking.x-k8s.io/v1alpha1
  kind: EndpointPickerConfig
  plugins:
  - type: prefill-header-handler
  - type: prefill-filter
  - type: decode-filter
  - type: max-score-picker
  - type: queue-scorer
    parameters:
      hashBlockSize: 5
      maxPrefixBlocksToMatch: 256
      lruCapacityPerServer: 31250
  - type: pd-profile-handler
    parameters:
      threshold: 0
      hashBlockSize: 5
  schedulingProfiles:
  - name: prefill
    plugins:
    - pluginRef: prefill-filter
    - pluginRef: queue-scorer
      weight: 1.0
    - pluginRef: max-score-picker
  - name: decode
    plugins:
    - pluginRef: decode-filter
    - pluginRef: queue-scorer
      weight: 1.0
    - pluginRef: max-score-picker
EOF

# Routing configuration (via modelservice)
export LLMDBENCH_VLLM_MODELSERVICE_INFERENCE_MODEL=true
export LLMDBENCH_VLLM_MODELSERVICE_INFERENCE_POOL=true
export LLMDBENCH_VLLM_MODELSERVICE_EPP=true

export LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_TAG=v0.2.0
# export LLMDBENCH_LLMD_ROUTINGSIDECAR_CONNECTOR=nixlv2 # already the default
# export LLMDBENCH_LLMD_ROUTINGSIDECAR_DEBUG_LEVEL=3

# Prefill and Decode configiration (via modelservice)

export LLMDBENCH_VLLM_MODELSERVICE_MULTINODE=true

# export LLMDBENCH_LLMD_IMAGE_NAME=llm-d-dev@sha256
# export LLMDBENCH_LLMD_IMAGE_TAG=dcb6b80a53d058e62dcbfc1166bf9e78419a62ea1e424489c85bc872f229a8e7
export LLMDBENCH_LLMD_IMAGE_NAME=llm-d
export LLMDBENCH_LLMD_IMAGE_TAG=v0.2.0

export LLMDBENCH_VLLM_COMMON_ENVVARS_TO_YAML=$(mktemp)
cat << EOF > $LLMDBENCH_VLLM_COMMON_ENVVARS_TO_YAML
- name: VLLM_FUSED_MOE_CHUNK_SIZE
  value: "1024"
- name: DP_SIZE_LOCAL
  value: "1"
- name: TRITON_LIBCUDA_PATH
  value: "/usr/lib64"
- name: VLLM_SKIP_P2P_CHECK
  value: "1"
- name: VLLM_RANDOMIZE_DP_DUMMY_INPUTS
  value: "1"
- name: VLLM_ALL2ALL_BACKEND
  value: "naive"
- name: NVIDIA_GDRCOPY
  value: "enabled"
- name: NVSHMEM_DEBUG
  value: "INFO"
- name: NVSHMEM_REMOTE_TRANSPORT
  value: "ibgda"
- name: NVSHMEM_IB_ENABLE_IBGDA
  value: "true"
- name: NVSHMEM_BOOTSTRAP_UID_SOCK_IFNAME
  value: "eth0"
- name: GLOO_SOCKET_IFNAME
  value: "eth0"
- name: NCCL_SOCKET_IFNAME
  value: "eth0"
- name: NCCL_IB_HCA
  value: "ibp"
- name: VLLM_LOGGING_LEVEL
  value: "INFO"
EOF

# export LLMDBENCH_VLLM_MODELSERVICE_MOUNT_MODEL_VOLUME_OVERRIDE=false
export LLMDBENCH_VLLM_MODELSERVICE_DECODE_REPLICAS=1
export LLMDBENCH_VLLM_MODELSERVICE_DECODE_DATA_PARALLELISM=2
export LLMDBENCH_VLLM_MODELSERVICE_DECODE_TENSOR_PARALLELISM=1
export LLMDBENCH_VLLM_MODELSERVICE_DECODE_ACCELERATOR_NR=1
# MK not in infra cicd 
# export LLMDBENCH_VLLM_MODELSERVICE_DECODE_CPU_NR=32
# export LLMDBENCH_VLLM_MODELSERVICE_DECODE_CPU_MEM=512Gi
# end MK
# Uncomment the following line to enable multi-nic
#export LLMDBENCH_VLLM_MODELSERVICE_DECODE_PODANNOTATIONS=deployed-by:$(id -un),modelservice:llm-d-benchmark,k8s.v1.cni.cncf.io/networks:multi-nic-compute
# Uncomment the following two lines to enable roce/gdr (or switch to rdma/ib for infiniband)
#export LLMDBENCH_VLLM_MODELSERVICE_DECODE_NETWORK_RESOURCE=rdma/roce_gdr
#export LLMDBENCH_VLLM_MODELSERVICE_DECODE_NETWORK_NR=4
# MK not in infra cicd
# export LLMDBENCH_VLLM_COMMON_EPHEMERAL_STORAGE_RESOURCE=${LLMDBENCH_VLLM_COMMON_EPHEMERAL_STORAGE_RESOURCE:-}
# export LLMDBENCH_VLLM_COMMON_EPHEMERAL_STORAGE_NR=${LLMDBENCH_VLLM_COMMON_EPHEMERAL_STORAGE_NR:-}
# export LLMDBENCH_VLLM_COMMON_EPHEMERAL_STORAGE_RESOURCE=ephemeral-storage
# export LLMDBENCH_VLLM_COMMON_EPHEMERAL_STORAGE_NR=64Gi
# end MK

export LLMDBENCH_VLLM_MODELSERVICE_DECODE_MODEL_COMMAND=custom

export LLMDBENCH_VLLM_MODELSERVICE_DECODE_EXTRA_ARGS=$(mktemp)
cat << EOF > $LLMDBENCH_VLLM_MODELSERVICE_DECODE_EXTRA_ARGS
START_RANK=\$(( \${LWS_WORKER_INDEX:-0} * DP_SIZE_LOCAL ))
        source /opt/vllm/bin/activate
        exec vllm serve /model-cache/models/REPLACE_ENV_LLMDBENCH_DEPLOY_CURRENT_MODEL \
--port REPLACE_ENV_LLMDBENCH_VLLM_MODELSERVICE_DECODE_INFERENCE_PORT \
--enforce-eager \
--max-model-len 4096 \
--disable-log-requests \
--disable-uvicorn-access-log \
--enable-expert-parallel \
--data-parallel-hybrid-lb \
--tensor-parallel-size \$TP_SIZE \
--data-parallel-size \$((LWS_GROUP_SIZE * DP_SIZE_LOCAL)) \
--data-parallel-size-local \$DP_SIZE_LOCAL \
--data-parallel-address \${LWS_LEADER_ADDRESS} \
--data-parallel-rpc-port 5555 \
--data-parallel-start-rank \$START_RANK \
--trust-remote-code \
--kv_transfer_config "{\"kv_connector\":\"NixlConnector\",\"kv_role\":\"kv_both\"}"
EOF
export LLMDBENCH_VLLM_MODELSERVICE_EXTRA_CONTAINER_CONFIG=$(mktemp)
cat << EOF > ${LLMDBENCH_VLLM_MODELSERVICE_EXTRA_CONTAINER_CONFIG}
workingDir: /code
imagePullPolicy: Always
EOF

export LLMDBENCH_VLLM_MODELSERVICE_EXTRA_VOLUME_MOUNTS=$(mktemp)
cat << EOF > ${LLMDBENCH_VLLM_MODELSERVICE_EXTRA_VOLUME_MOUNTS}
- name: dshm
  mountPath: /dev/shm
EOF

export LLMDBENCH_VLLM_MODELSERVICE_EXTRA_VOLUMES=$(mktemp)
cat << EOF > ${LLMDBENCH_VLLM_MODELSERVICE_EXTRA_VOLUMES}
- name: dshm
  emptyDir:
    medium: Memory
    sizeLimit: 1Gi
EOF

export LLMDBENCH_VLLM_MODELSERVICE_PREFILL_REPLICAS=1

export LLMDBENCH_VLLM_MODELSERVICE_DECODE_TENSOR_PARALLELISM=1
# Uncomment the following line to enable multi-nic
#export LLMDBENCH_VLLM_MODELSERVICE_DECODE_PODANNOTATIONS=deployed-by:$(id -un),modelservice:llm-d-benchmark,k8s.v1.cni.cncf.io/networks:multi-nic-compute
# Uncomment the following two lines to enable roce/gdr (or switch to rdma/ib for infiniband)
#export LLMDBENCH_VLLM_MODELSERVICE_DECODE_NETWORK_RESOURCE=rdma/roce_gdr
#export LLMDBENCH_VLLM_MODELSERVICE_DECODE_NETWORK_NR=4
export LLMDBENCH_VLLM_MODELSERVICE_DECODE_DATA_PARALLELISM=2
export LLMDBENCH_VLLM_MODELSERVICE_DECODE_TENSOR_PARALLELISM=1
# MK not in infra cicd
# export LLMDBENCH_VLLM_MODELSERVICE_DECODE_CPU_NR=16
# export LLMDBENCH_VLLM_MODELSERVICE_DECODE_CPU_MEM=64Gi
# end MK

export LLMDBENCH_VLLM_MODELSERVICE_PREFILL_MODEL_COMMAND=custom
export LLMDBENCH_VLLM_MODELSERVICE_PREFILL_EXTRA_ARGS=$(mktemp)
cat << EOF > $LLMDBENCH_VLLM_MODELSERVICE_PREFILL_EXTRA_ARGS
START_RANK=\$(( \${LWS_WORKER_INDEX:-0} * DP_SIZE_LOCAL ))

        source /opt/vllm/bin/activate
        exec vllm serve /model-cache/models/REPLACE_ENV_LLMDBENCH_DEPLOY_CURRENT_MODEL \
--port REPLACE_ENV_LLMDBENCH_VLLM_MODELSERVICE_PREFILL_INFERENCE_PORT \
--enforce-eager \
--max-model-len 4096 \
--disable-log-requests \
--disable-uvicorn-access-log \
--enable-expert-parallel \
--data-parallel-hybrid-lb \
--tensor-parallel-size \$TP_SIZE \
--data-parallel-size \$((LWS_GROUP_SIZE * DP_SIZE_LOCAL)) \
--data-parallel-size-local \$DP_SIZE_LOCAL \
--data-parallel-address \${LWS_LEADER_ADDRESS} \
--data-parallel-rpc-port 5555 \
--data-parallel-start-rank \$START_RANK \
--trust-remote-code \
--kv_transfer_config "{\"kv_connector\":\"NixlConnector\",\"kv_role\":\"kv_both\"}"
EOF
