<script lang="ts">
  import { onMount, afterUpdate } from 'svelte';
  import {
    chatModelGlobal,
    activeChatGlobal,
    chatModelIdInitiatedGlobal,
    downloadedModels,
    useKnowledgeBase
  } from "../store";
  import InstallToastNotification from './InstallToastNotification.svelte';
  import {
    getSearchVectorDbTool,
    searchUserKnowledgebase,
    //storeEmbeddings,
    //loadExistingVectorStore,
    //checkUserHasKnowledgeBase
  } from "../helpers/vector_database";
  import SelectModel from "./SelectModel.svelte";
  import ChatBox from "./ChatBox.svelte";

  import { determineInferenceParameters } from '../helpers/user_settings';

  // Reactive statement to check if the user has already downloaded at least one AI model
  $: userHasDownloadedAtLeastOneModel = $downloadedModels.length > 0;

  const workerPath = './worker.ts';

  let showToast = false;

  function isPWAInstalled() {
    // @ts-ignore
    return (window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone);
  };

  let isChatBoxReady = false;

  onMount(() => {
    if (!userHasDownloadedAtLeastOneModel && !isPWAInstalled()) {
      // Check if the toast has already been shown in this session
      const hasShownToast = sessionStorage.getItem('hasShownToast');

      if (!hasShownToast) {
        showToast = true; // Show toast on load

        // Set in sessionStorage that the toast has been shown
        sessionStorage.setItem('hasShownToast', 'true');

        // Automatically hide the toast after 8 seconds
        setTimeout(() => {
          showToast = false;
        }, 8000);
      };
    };
  });

  afterUpdate(() => {
    if ($chatModelIdInitiatedGlobal && !isChatBoxReady) {
      isChatBoxReady = true;
    }
  });

  let vectorDbSearchTool;
  let useSessionVectorDb = false;

  async function setVectorDbSearchTool(pathToInput) {
    vectorDbSearchTool = await getSearchVectorDbTool(pathToInput);
    useSessionVectorDb = true;
  };

  // Debug Android
  //let debugOutput = "";

  function setLabel(id: string, text: string) {
    const label = document.getElementById(id);
    if (label == null) {
      throw Error("Cannot find label " + id);
    }
    label.innerText = text;
  };

  const generateProgressCallback = (_step: number, message: string) => {
    setLabel("generate-label", message);
  };

  async function getChatModelResponse(prompt, progressCallback = generateProgressCallback) {
    try {
     
      if ((vectorDbSearchTool && useSessionVectorDb) || $useKnowledgeBase) {
       
        // Add content from local knowledge base if activated
        let additionalContentToProvide = "";
        additionalContentToProvide = " Additional content (use this if relevant to the User Prompt): ";
        try {
          const promptContent = prompt[prompt.length - 1].content;
          if (vectorDbSearchTool && useSessionVectorDb) {
            try {
              let vectorDbSearchToolResponse = await vectorDbSearchTool.func(promptContent);
              vectorDbSearchToolResponse = JSON.parse(vectorDbSearchToolResponse);
              for (let index = 0; index < vectorDbSearchToolResponse.existingChatsFoundInLocalDatabase.length; index++) {
                const additionalEntry = vectorDbSearchToolResponse.existingChatsFoundInLocalDatabase[index];
                additionalContentToProvide += "  ";
                additionalContentToProvide += additionalEntry.content;
              };
            } catch (error) {
              console.error("Error in getChatModelResponse vectorDbSearchTool");
              console.error(error.toString());
              
            };
          };
          if ($useKnowledgeBase) {
            try {
              let userKnowledgeBaseResponse = await searchUserKnowledgebase(promptContent);
              if (userKnowledgeBaseResponse) {
                additionalContentToProvide += "  ";
                additionalContentToProvide += userKnowledgeBaseResponse;
              };
            } catch (error) {
              console.error("Error in getChatModelResponse vectorDbSearchTool");
              console.error(error.toString());
              
            };
          };
          // Compose the final prompt
          const additionalContentEntry = { role: 'user', content: additionalContentToProvide, name: 'UserKnowledgeBase' };
          prompt = [...prompt, additionalContentEntry];
        } catch (error) {
          console.error("Error in getChatModelResponse getting additionalContentToProvide");
          console.error(error.toString());
         
        };
      };
      try {
        
        let curMessage = "";
        let stepCount = 0;
        // determine inference parameters to use
        const inferenceParameters = await determineInferenceParameters();
        prompt.unshift({
          role: "system",
          content: inferenceParameters.system_prompt,
        });
        
        const completion = await $chatModelGlobal.chat.completions.create({
          stream: true,
          messages: prompt,
          temperature: inferenceParameters.temperature,
          max_tokens: inferenceParameters.max_tokens,
        });
        console.log("Get chatModelGlobal here")
        try {
          for await (const chunk of completion) {
            
            try {
              const curDelta = chunk.choices[0].delta.content;
              if (curDelta) {
                curMessage += curDelta;
              };
              progressCallback(stepCount, curMessage);
              stepCount ++;
            } catch (error) {
              console.error("Error in getChatModelResponse progressCallback");
              console.error(error.toString());
              
            };
          };
        } catch (error) {
          console.error("Error in getChatModelResponse completion loop");
          console.error(error.toString());
          
        };
      } catch (error) {
        console.error("Error in getChatModelResponse completion");
        console.error(error.toString());
       
      };

      try {
       
        const reply = await $chatModelGlobal.getMessage();
       
        return reply;
      } catch (error) {
        console.error("Error in getChatModelResponse reply");
        console.error(error.toString());
       
      };
    } catch (error) {
      console.error("Error in getChatModelResponse");
      console.error(error.toString());
     
    };
    // if no reply was returned, an error occurred
    throw new Error('An error occurred');
  };
</script>

<div id="chatinterface" class="flex flex-col p-4 pb-24 max-w-6xl mx-auto w-full">
  {#if !$chatModelIdInitiatedGlobal}
    <SelectModel onlyShowDownloadedModels={true} autoInitiateSelectedModel={true}/>
  {:else if isChatBoxReady}
    {#key $activeChatGlobal}
      <ChatBox modelCallbackFunction={getChatModelResponse} chatDisplayed={$activeChatGlobal} callbackSearchVectorDbTool={setVectorDbSearchTool}/>
    {/key}
  {:else}
    <p>Loading chat interface...</p>
  {/if}
</div>

{#key showToast}
  <InstallToastNotification showToast={showToast} />
{/key}
