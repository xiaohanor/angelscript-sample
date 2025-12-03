/**
 * Makes sure that feet stay planted on the ground.
 */
class USkylineBossFootGroundedCapability : USkylineBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default CapabilityTags.Add(SkylineBossTags::SkylineBossFootGrounded);

	TArray<USkylineBossLegComponent> LegComponents;
	USkylineBossFootTargetComponent FootTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Boss.GetComponentsByClass(LegComponents);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (USkylineBossLegComponent LegComponent : LegComponents)
		{
			LegComponent.PlacementForward = LegComponent.Leg.ActorForwardVector;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (USkylineBossLegComponent LegComponent : LegComponents)
		{
			if (!LegComponent.bIsGrounded)
				continue;

			FVector TargetLocation = LegComponent.FootTargetComponent.WorldLocation;
//			FRotator TargetRotation = LegComponent.FootTargetComponent.WorldRotation;
			FRotator TargetRotation = FRotator::MakeFromZX(LegComponent.FootTargetComponent.UpVector, LegComponent.PlacementForward);

			LegComponent.Leg.SetFootAnimationTargetLocationAndRotation(
				TargetLocation,
				TargetRotation
			);
		}

		Boss.bCanWalk = true;
	}
}