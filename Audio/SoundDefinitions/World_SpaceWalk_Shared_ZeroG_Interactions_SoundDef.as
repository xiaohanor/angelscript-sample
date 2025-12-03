
UCLASS(Abstract)
class UWorld_SpaceWalk_Shared_ZeroG_Interactions_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHookFinishedRetracting(){}

	UFUNCTION(BlueprintEvent)
	void OnHookDetached(){}

	UFUNCTION(BlueprintEvent)
	void OnHookAttached(){}

	UFUNCTION(BlueprintEvent)
	void OnHookLaunched(){}

	UFUNCTION(BlueprintEvent)
	void OnStoppedThrusting(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedThrusting(){}

	/* END OF AUTO-GENERATED CODE */

	UPlayerMovementComponent MoveComp;
	private bool bImpactedLastFrame;
	float LastImpactTime = 0;

	UFUNCTION(BlueprintEvent)
	void OnPlayerImpact(float Strength) {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveComp = UPlayerMovementComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastImpactTime = 0;
		bImpactedLastFrame = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(MoveComp.HasAnyValidBlockingImpacts())
		{
			if (!bImpactedLastFrame && Time::GetAudioTimeSince(LastImpactTime) > 0.3)
			{
				LastImpactTime = Time::AudioTimeSeconds;
				OnPlayerImpact(MoveComp.PreviousVelocity.Size());
			}
			bImpactedLastFrame = true;
		}
		else
		{
			bImpactedLastFrame  = false;
		}
	}

}