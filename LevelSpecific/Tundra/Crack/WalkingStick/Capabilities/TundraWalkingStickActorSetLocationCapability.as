class UTundraWalkingStickActorSetLocationCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::PostWork;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WalkingStick.bGameplaySpider)
			return false;

		if(WalkingStick.CurrentState == ETundraWalkingStickState::None)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WalkingStick.bGameplaySpider)
			return true;

		if(WalkingStick.CurrentState == ETundraWalkingStickState::None)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// You may think why not just attach the actor to the bone directly? Well, that's what I thought as well,
		// but chaos didn't seem to like that (nothing collided with any colliders that were attached to the bone, adding a component to the BP didn't work either)
		FTransform HipsTransform = WalkingStick.Mesh.GetSocketTransform(n"Hips");
		for(int i = 0; i < WalkingStick.ActorsToSetLocationToHips.Num(); i++)
		{
			AActor Current = WalkingStick.ActorsToSetLocationToHips[i];
			FTransform ReleativeTransform = WalkingStick.ActorsToSetLocationRelativeTransform[i];
			FHitResult Hit;
			Current.SetActorTransform(ReleativeTransform * HipsTransform, false, Hit, true);
		}
	}
}