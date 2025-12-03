UCLASS(Abstract)
class AAISummitWyrm : ABasicAICharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
	default DisableComp.AutoDisableRange = 500000.0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitWyrmFollowSplineComponent FollowSplineComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	default CapabilityComp.DefaultCapabilities.Add(n"FlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmFlyAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmHeadRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmTailCapability");

	//Static siege mode
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmStaticLightningAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitWyrmStaticShockwaveCapability");

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;

	UPROPERTY(DefaultComponent)
	USummitWyrmPivotComponent Pivot;

	UPROPERTY(DefaultComponent)
	USummitWyrmTailComponent TailComponent;

	UPROPERTY(DefaultComponent)
	UStormSiegeDetectPlayerComponent SeigeDetectPlayerComp;
	default SeigeDetectPlayerComp.AggressionRange = 130000.0;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float ShockwaveWaitTime = 7.0;
	float LightningWaitTime = 5.0;
	float ShockwaveAttackDelay = 2.5;

	bool bSiegeActive = false;
	
	UFUNCTION()
	void ResetTrail()
	{
		TailComponent.ResetTail(ActorForwardVector, ActorUpVector);
	}

	UFUNCTION()
	void ActivateWyrm()
	{
		if (IsCapabilityTagBlocked(BasicAITags::Behaviour))
			UnblockCapabilities(BasicAITags::Behaviour, this);
	}

	UFUNCTION()
	void DeactivateWyrm()
	{
		if (!IsCapabilityTagBlocked(BasicAITags::Behaviour))
			BlockCapabilities(BasicAITags::Behaviour, this);
	}

	UFUNCTION()
	void ActivateSiege()
	{
		bSiegeActive = true;
		// BlockCapabilities(n"SplineMovement", this);
		// BlockCapabilities(BasicAITags::Behaviour, this);
	}

	UFUNCTION()
	void DeactivateSiege()
	{
		bSiegeActive = false;
		// UnblockCapabilities(n"SplineMovement", this);
		// UnblockCapabilities(BasicAITags::Behaviour, this);
	}

}
