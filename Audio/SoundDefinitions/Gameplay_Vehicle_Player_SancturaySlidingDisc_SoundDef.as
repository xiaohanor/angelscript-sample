
UCLASS(Abstract)
class UGameplay_Vehicle_Player_SancturaySlidingDisc_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnAirborne(){}

	UFUNCTION(BlueprintEvent)
	void OnHydra(){}

	UFUNCTION(BlueprintEvent)
	void OnLanded(FOnSlidingDiscLandedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnCollisionImpact(FOnSlidingDiscCollidedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDiscDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void OnEatenByHydra(){}

	/* END OF AUTO-GENERATED CODE */

	UHazeMovementComponent MoveComp;

	ASlidingDisc Disc; 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Disc.bIsSliding;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		 if (!Disc.bIsSliding)
		 	return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsSliding() const
	{
		return Disc.bIsSliding;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Disc = Cast<ASlidingDisc>(HazeOwner);
		MoveComp = UHazeMovementComponent::Get(HazeOwner);
	}

	private UPhysicalMaterialAudioAsset LastPhysMat = nullptr;
	UFUNCTION(BlueprintEvent)
	void OnSlidingMaterialChanged(UPhysicalMaterialAudioAsset AudioPhysMat) {};

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(MoveComp.IsOnAnyGround())
		{
			auto PhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.ConvertToHitResult(), FHazeTraceSettings()).AudioAsset);
			if(PhysMat != LastPhysMat)
				OnSlidingMaterialChanged(PhysMat);

			LastPhysMat = PhysMat;
		}
		else
			LastPhysMat = nullptr;
	}
}