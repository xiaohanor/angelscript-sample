class UTundraBossIceKingSlideActorCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	
	ATundraBossIceKingSlideActor SlideActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlideActor = Cast<ATundraBossIceKingSlideActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SlideActor.bShouldPlayAnimation)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SlideActor.bShouldPlayAnimation)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SlideActor.bShouldPlayAnimation = false;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = SlideActor.Animation;
		Params.bLoop = false;
		Params.BlendTime = 0;
		SlideActor.SkelMesh.PlaySlotAnimation(Params);
		SlideActor.SkelMesh.SetHiddenInGame(false);
	}
};