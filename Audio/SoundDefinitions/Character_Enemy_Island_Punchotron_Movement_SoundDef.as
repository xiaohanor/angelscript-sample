
UCLASS(Abstract)
class UCharacter_Enemy_Island_Punchotron_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartDying(){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnDamage(FIslandPunchotronProjectileImpactParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStunned(){}

	UFUNCTION(BlueprintEvent)
	void OnLanded(FIslandPunchotronOnLandedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningAttackTelegraphingStart(FIslandPunchotronSpinningAttackTelegraphingParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningAttackTelegraphingStop(){}

	UFUNCTION(BlueprintEvent)
	void OnHaywireAttackTelegraphingStart(FIslandPunchotronHaywireAttackTelegraphingParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHaywireAttackTelegraphingStop(){}

	UFUNCTION(BlueprintEvent)
	void OnWheelchairKickAttackTelegraphingStart(FIslandPunchotronWheelchairKickAttackTelegraphingParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnWheelchairKickAttackTelegraphingStop(){}

	UFUNCTION(BlueprintEvent)
	void OnEyeTelegraphingStart(FIslandPunchotronEyeTelegraphingParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnEyeTelegraphingStop(){}

	UFUNCTION(BlueprintEvent)
	void OnProximityAttackTelegraphingStart(FIslandPunchotronProximityAttackTelegraphingParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnProximityAttackTelegraphingStop(){}

	UFUNCTION(BlueprintEvent)
	void OnJetsStart(FIslandPunchotronJetsParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnJetsStop(){}

	UFUNCTION(BlueprintEvent)
	void OnSmallJetsStart(FIslandPunchotronJetsParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSmallJetSingleStart(FIslandPunchotronSingleJetParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSmallJetsStop(){}

	UFUNCTION(BlueprintEvent)
	void OnSkateLeftStart(FIslandPunchotronSingleJetParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSkateLeftEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnSkateRightStart(FIslandPunchotronSingleJetParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSkateRightEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnFlameThrowerStart(FIslandPunchotronFlameThrowerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFlameThrowerStop(){}

	UFUNCTION(BlueprintEvent)
	void OnExhaustVentStart(FIslandPunchotronExhaustVentParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnExhaustVentStop(){}

	UFUNCTION(BlueprintEvent)
	void OnSawbladeAttackSwing(){}

	UFUNCTION(BlueprintEvent)
	void OnCobraAttackTelegraphStart(){}

	UFUNCTION(BlueprintEvent)
	void OnCobraAttackBrakeStart(){}

	UFUNCTION(BlueprintEvent)
	void OnKickAttackTelegraphStart(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	bool bIsSidescroller = false;

	const float MAX_ROTATION_ANGLE_DELTA = 3.75;

	private FQuat PreviousLeftSawBladeRotation;
	private FQuat PreviousRightSawBladeRotation;

	UPROPERTY(BlueprintReadOnly)
	ABasicAICharacter Punchotron;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Punchotron = Cast<ABasicAICharacter>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bIsSidescroller)
		{
			FVector2D _;
			float _Y = 0.0;
			float X = 0.0;
			if(Audio::GetScreenPositionRelativePanningValue(Punchotron.ActorLocation, _, X, _Y))
			{
				DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetSawbladeRotationDeltaCombined()
	{
		const FQuat LeftSawBladeRotation = Punchotron.Mesh.GetSocketTransform(n"LeftHand", ERelativeTransformSpace::RTS_ParentBoneSpace).Rotation;
		const FQuat RightSawBladeRotation = Punchotron.Mesh.GetSocketTransform(n"RightHand", ERelativeTransformSpace::RTS_ParentBoneSpace).Rotation;

		float Delta = Math::Max(LeftSawBladeRotation.AngularDistance(PreviousLeftSawBladeRotation), RightSawBladeRotation.AngularDistance(PreviousRightSawBladeRotation));
		Delta = Math::Saturate(Delta / MAX_ROTATION_ANGLE_DELTA);

		PreviousLeftSawBladeRotation = LeftSawBladeRotation;
		PreviousRightSawBladeRotation = RightSawBladeRotation;	

		return Delta;
	}
}