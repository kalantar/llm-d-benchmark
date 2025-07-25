#!/usr/bin/env bash
source ${LLMDBENCH_CONTROL_DIR}/env.sh

if [[ $LLMDBENCH_CONTROL_ENVIRONMENT_TYPE_DEPLOYER_ACTIVE -eq 1 ]]; then
  extract_environment

  for model in ${LLMDBENCH_DEPLOY_MODEL_LIST//,/ }; do

    if [[ $LLMDBENCH_VLLM_DEPLOYER_VALUES_FILE == "fromenv" ]]; then
      cat << EOF > $LLMDBENCH_CONTROL_WORK_DIR/setup/yamls/${LLMDBENCH_CURRENT_STEP}_deployer_values.yaml
sampleApplication:
  enabled: true
  baseConfigMapRefName: ${LLMDBENCH_VLLM_DEPLOYER_BASECONFIGMAPREFNAME}
  model:
    modelArtifactURI: pvc://model-pvc/models/$(model_attribute $model model)
    modelName: "$(model_attribute $model model)"
    auth:
      hfToken:
        name: llm-d-hf-token
        key: HF_TOKEN
  resources:
    limits:
      $(echo "$LLMDBENCH_VLLM_COMMON_ACCELERATOR_RESOURCE: \"${LLMDBENCH_VLLM_COMMON_ACCELERATOR_NR}\"")
    requests:
      cpu: "${LLMDBENCH_VLLM_COMMON_CPU_NR}"
      memory: ${LLMDBENCH_VLLM_COMMON_CPU_MEM}
      $(echo "$LLMDBENCH_VLLM_COMMON_ACCELERATOR_RESOURCE: \"${LLMDBENCH_VLLM_COMMON_ACCELERATOR_NR}\"")
  inferencePoolPort: ${LLMDBENCH_VLLM_COMMON_INFERENCE_PORT}
  prefill:
    replicas: ${LLMDBENCH_VLLM_DEPLOYER_PREFILL_REPLICAS}
    extraArgs: $(render_string ${LLMDBENCH_VLLM_DEPLOYER_PREFILL_EXTRA_ARGS} $model)
  decode:
    replicas: ${LLMDBENCH_VLLM_DEPLOYER_DECODE_REPLICAS}
    extraArgs: $(render_string ${LLMDBENCH_VLLM_DEPLOYER_DECODE_EXTRA_ARGS} $model)

gateway:
  gatewayClassName: ${LLMDBENCH_VLLM_DEPLOYER_GATEWAY_CLASS_NAME}

modelservice:
  replicas: $LLMDBENCH_VLLM_DEPLOYER_MODELSERVICE_REPLICAS

  image:
    registry: $LLMDBENCH_LLMD_MODELSERVICE_IMAGE_REGISTRY
    repository: ${LLMDBENCH_LLMD_MODELSERVICE_IMAGE_REPO}/${LLMDBENCH_LLMD_MODELSERVICE_IMAGE_NAME}
    tag: $(get_image ${LLMDBENCH_LLMD_MODELSERVICE_IMAGE_REGISTRY} ${LLMDBENCH_LLMD_MODELSERVICE_IMAGE_REPO} ${LLMDBENCH_LLMD_MODELSERVICE_IMAGE_NAME} ${LLMDBENCH_LLMD_MODELSERVICE_IMAGE_TAG} 1)

  epp:
    image:
      registry: ${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_REGISTRY}
      repository: ${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_REPO}/${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_NAME}
      tag: $(get_image ${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_REGISTRY} ${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_REPO} ${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_NAME} ${LLMDBENCH_LLMD_INFERENCESCHEDULER_IMAGE_TAG} 1)

    metrics:
      enabled: true
    defaultEnvVarsOverride:
      - name: ENABLE_KVCACHE_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_ENABLE_KVCACHE_AWARE_SCORER}"
      - name: KVCACHE_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_KVCACHE_AWARE_SCORER_WEIGHT}"
      - name: ENABLE_PREFIX_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_ENABLE_PREFIX_AWARE_SCORER}"
      - name: PREFIX_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFIX_AWARE_SCORER_WEIGHT}"
      - name: ENABLE_LOAD_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_ENABLE_LOAD_AWARE_SCORER}"
      - name: LOAD_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_LOAD_AWARE_SCORER_WEIGHT}"
      - name: ENABLE_SESSION_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_ENABLE_SESSION_AWARE_SCORER}"
      - name: SESSION_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_SESSION_AWARE_SCORER_WEIGHT}"
      - name: PD_ENABLED
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PD_ENABLED}"
      - name: PD_PROMPT_LEN_THRESHOLD
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PD_PROMPT_LEN_THRESHOLD}"
      - name: PREFILL_ENABLE_KVCACHE_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_ENABLE_KVCACHE_AWARE_SCORER}"
      - name: PREFILL_KVCACHE_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_KVCACHE_AWARE_SCORER_WEIGHT}"
      - name: PREFILL_ENABLE_LOAD_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_ENABLE_LOAD_AWARE_SCORER}"
      - name: PREFILL_LOAD_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_LOAD_AWARE_SCORER_WEIGHT}"
      - name: PREFILL_ENABLE_PREFIX_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_ENABLE_PREFIX_AWARE_SCORER}"
      - name: PREFILL_PREFIX_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_PREFIX_AWARE_SCORER_WEIGHT}"
      - name: PREFILL_ENABLE_SESSION_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_ENABLE_SESSION_AWARE_SCORER}"
      - name: PREFILL_SESSION_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_PREFILL_SESSION_AWARE_SCORER_WEIGHT}"
      - name: DECODE_ENABLE_KVCACHE_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_ENABLE_KVCACHE_AWARE_SCORER}"
      - name: DECODE_KVCACHE_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_KVCACHE_AWARE_SCORER_WEIGHT}"
      - name: DECODE_ENABLE_LOAD_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_ENABLE_LOAD_AWARE_SCORER}"
      - name: DECODE_LOAD_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_LOAD_AWARE_SCORER_WEIGHT}"
      - name: DECODE_ENABLE_PREFIX_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_ENABLE_PREFIX_AWARE_SCORER}"
      - name: DECODE_PREFIX_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_PREFIX_AWARE_SCORER_WEIGHT}"
      - name: DECODE_ENABLE_SESSION_AWARE_SCORER
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_ENABLE_SESSION_AWARE_SCORER}"
      - name: DECODE_SESSION_AWARE_SCORER_WEIGHT
        value: "${LLMDBENCH_VLLM_DEPLOYER_EPP_DECODE_SESSION_AWARE_SCORER_WEIGHT}"

  prefill :
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: $(echo $LLMDBENCH_VLLM_COMMON_AFFINITY | cut -d ':' -f 1)
              operator: In
              values:
              - $(echo $LLMDBENCH_VLLM_COMMON_AFFINITY | cut -d ':' -f 2)

  decode :
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: $(echo $LLMDBENCH_VLLM_COMMON_AFFINITY | cut -d ':' -f 1)
              operator: In
              values:
              - $(echo $LLMDBENCH_VLLM_COMMON_AFFINITY | cut -d ':' -f 2)

  vllm:
    image:
      registry: $LLMDBENCH_LLMD_IMAGE_REGISTRY
      repository: $LLMDBENCH_LLMD_IMAGE_REPO/${LLMDBENCH_LLMD_IMAGE_NAME}
      tag: $(get_image ${LLMDBENCH_LLMD_IMAGE_REGISTRY} ${LLMDBENCH_LLMD_IMAGE_REPO} ${LLMDBENCH_LLMD_IMAGE_NAME} ${LLMDBENCH_LLMD_IMAGE_TAG} 1)

    metrics:
      enabled: true

  routingProxy:
    image:
      registry: ${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_REGISTRY}
      repository: ${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_REPO}/${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_NAME}
      tag: $(get_image ${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_REGISTRY} ${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_REPO} ${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_NAME} ${LLMDBENCH_LLMD_ROUTINGSIDECAR_IMAGE_TAG} 1)

  inferenceSimulator:
    image:
      registry: ${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_REGISTRY}
      repository: ${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_REPO}/${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_NAME}
      tag: $(get_image ${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_REGISTRY} ${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_REPO} ${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_NAME} ${LLMDBENCH_LLMD_INFERENCESIM_IMAGE_TAG} 1)
EOF
      LLMDBENCH_VLLM_DEPLOYER_VALUES_FILE=$LLMDBENCH_CONTROL_WORK_DIR/setup/yamls/${LLMDBENCH_CURRENT_STEP}_deployer_values.yaml
    fi

    sanitized_model_name=$(model_attribute $model as_label)
    llmd_opts="--skip-infra --release ${LLMDBENCH_VLLM_DEPLOYER_RELEASE} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} --storage-class ${LLMDBENCH_VLLM_COMMON_PVC_STORAGE_CLASS} --storage-size ${LLMDBENCH_VLLM_COMMON_PVC_MODEL_CACHE_SIZE} --values-file $LLMDBENCH_VLLM_DEPLOYER_VALUES_FILE --gateway ${LLMDBENCH_VLLM_DEPLOYER_GATEWAY_CLASS_NAME} --context $LLMDBENCH_CONTROL_WORK_DIR/environment/context.ctx"
    announce "🚀 Calling llm-d-deployer with options \"${llmd_opts}\"..."
    llmdbench_execute_cmd "cd $LLMDBENCH_DEPLOYER_DIR/llm-d-deployer/quickstart; export HF_TOKEN=$LLMDBENCH_HF_TOKEN; ./llmd-installer.sh $llmd_opts" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE} 0
    announce "✅ llm-d-deployer completed successfully"

    announce "⏳ waiting for (decode) pods serving model ${model} to be created..."
    llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} wait --timeout=$((LLMDBENCH_CONTROL_WAIT_TIMEOUT / 2))s --for=create pod -l llm-d.ai/model=$sanitized_model_name,llm-d.ai/role=decode" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE} 1 2
    announce "✅ (decode) pods serving model ${model} created"

    announce "⏳ waiting for (prefill) pods serving model ${model} to be created..."
    llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} wait --timeout=$((LLMDBENCH_CONTROL_WAIT_TIMEOUT / 2))s --for=create pod -l llm-d.ai/model=$sanitized_model_name,llm-d.ai/role=prefill" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE} 1 2
    announce "✅ (prefill) pods serving model ${model} created"

    announce "⏳ Waiting for (decode) pods serving model ${model} to be in \"Running\" state (timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s)..."
    llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} wait --timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s --for=jsonpath='{.status.phase}'=Running pod  -l llm-d.ai/model=$sanitized_model_name,llm-d.ai/role=decode" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE}
    announce "🚀 (decode) pods serving model ${model} running"

    announce "⏳ Waiting for (prefill) pods serving model ${model} to be in \"Running\" state (timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s)..."
    llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} wait --timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s --for=jsonpath='{.status.phase}'=Running pod  -l llm-d.ai/model=$sanitized_model_name,llm-d.ai/role=prefill" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE}
    announce "🚀 (prefill) pods serving model ${model} running"

    announce "⏳ Waiting for (decode) pods serving ${model} to be Ready (timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s)..."
    llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} wait --timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s --for=condition=Ready=True pod -l llm-d.ai/model=$sanitized_model_name,llm-d.ai/role=decode" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE}
    announce "🚀 (decode) pods serving model ${model} ready"

    announce "⏳ Waiting for (prefill) pods serving ${model} to be Ready (timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s)..."
    llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} wait --timeout=${LLMDBENCH_CONTROL_WAIT_TIMEOUT}s --for=condition=Ready=True pod -l llm-d.ai/model=$sanitized_model_name,llm-d.ai/role=prefill" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE}
    announce "🚀 (prefill) pods serving model ${model} ready"

    if [[ $LLMDBENCH_VLLM_DEPLOYER_ROUTE -ne 0 && $LLMDBENCH_CONTROL_DEPLOY_IS_OPENSHIFT -ne 0 ]]; then
      is_route=$(${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} get route -o name --ignore-not-found | grep -E "/${LLMDBENCH_VLLM_DEPLOYER_RELEASE}-inference-gateway-route$" || true)
      if [[ -z $is_route ]]
      then
        announce "📜 Exposing pods serving model ${model} as service..."
        llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} expose service/${LLMDBENCH_VLLM_DEPLOYER_RELEASE}-inference-gateway --target-port=${LLMDBENCH_VLLM_COMMON_INFERENCE_PORT} --name=${LLMDBENCH_VLLM_DEPLOYER_RELEASE}-inference-gateway-route" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE}
        announce "✅ Service for pods service model ${model} created"
      fi
      announce "✅ Model \"${model}\" and associated service deployed."
    fi

    reconfigure_gateway_after_deploy

    announce "✅ llm-d-deployer completed model deployment"

    srl=deployment,service,route,pods,secrets
    announce "ℹ️ A snapshot of the relevant (model-specific) resources on namespace \"${LLMDBENCH_VLLM_COMMON_NAMESPACE}\":"
    if [[ $LLMDBENCH_CONTROL_DRY_RUN -eq 0 ]]; then
      llmdbench_execute_cmd "${LLMDBENCH_CONTROL_KCMD} get --namespace ${LLMDBENCH_VLLM_COMMON_NAMESPACE} $srl" ${LLMDBENCH_CONTROL_DRY_RUN} ${LLMDBENCH_CONTROL_VERBOSE} 0
    fi
  done
else
  announce "⏭️ Environment types are \"${LLMDBENCH_DEPLOY_METHODS}\". Skipping this step."
fi
