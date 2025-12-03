class UBasicAIVoiceOverComponent : UActorComponent
{
	UPROPERTY()
	int VoiceOverID = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()	
	{
		CreateNewVoiceID();
	}

	UFUNCTION()
	int GetVoiceOverID()
	{
		return VoiceOverID;
	}

	int CreateNewVoiceID()
	{
		UBasicAIVoiceOverManager VOManager = Game::GetSingleton(UBasicAIVoiceOverManager);		
		VOManager.CreateNewVoiceID(Owner.Class, VoiceOverID);
		return VoiceOverID;
	}


};