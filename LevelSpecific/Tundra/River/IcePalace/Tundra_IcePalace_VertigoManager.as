class ATundra_IcePalace_VertigoManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilities.Add(n"Tundra_IcePalace_VertigoPlayerCapability");

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_IcePalace_VertigoCameraPoint> VertigoCameraPoints;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor MioSeq;
	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor ZoeSeq;
	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UCameraShakeBase> VertigoCamShake;

	UFUNCTION()
	void SetVertigoEnabled(bool bEnable, AHazePlayerCharacter Player)
	{
		if(bEnable)
		{
			UTundra_IcePalace_VertigoPlayerComponent Comp = UTundra_IcePalace_VertigoPlayerComponent::GetOrCreate(Player);
			if(Comp.bCapabilityActive)
				return;

			AHazeLevelSequenceActor Sequence = Player.IsMio() ? MioSeq : ZoeSeq;

			Comp.VertigoCameraPoints = VertigoCameraPoints;
			Comp.VertigoSeq = Sequence;
			Comp.bCapabilityActive = true;
			Comp.VertigoCameraShake = VertigoCamShake;
			Sequence.PlayLevelSequenceSimple(FOnHazeSequenceFinished(), Player);

			Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		}
		else
		{
			UTundra_IcePalace_VertigoPlayerComponent Comp = UTundra_IcePalace_VertigoPlayerComponent::GetOrCreate(Player);
			if(!Comp.bCapabilityActive)
				return;

			Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

			AHazeLevelSequenceActor Sequence = Player.IsMio() ? MioSeq : ZoeSeq;
			
			Comp.bCapabilityActive = false;
			BP_StopSequence(Sequence);
		}
	}

	//Stopping Seq from BP since the Stop() function didn't work.
	UFUNCTION(BlueprintEvent)
	void BP_StopSequence(AHazeLevelSequenceActor Seq)
	{}
};