
UCLASS(Abstract)
class UCharacter_Boss_Skyline_MrHammer_Hammer_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnShockwaveAttack(FOnShockwaveAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnInterruptGrabMashStop(FOnInterruptGrabMashData Data){}

	UFUNCTION(BlueprintEvent)
	void OnInterruptGrabMashStart(FOnInterruptGrabMashData Data){}

	UFUNCTION(BlueprintEvent)
	void OnVolleyTelegraphStop(){}

	UFUNCTION(BlueprintEvent)
	void OnVolleyTelegraphStart(FSkylineTorHammerOnVolleyTelegraphStartData Data){}

	UFUNCTION(BlueprintEvent)
	void OnSpiralTelegraphStop(){}

	UFUNCTION(BlueprintEvent)
	void OnSpiralTelegraphUpdate(FSkylineTorHammerOnSpiralTelegraphData Data){}

	UFUNCTION(BlueprintEvent)
	void OnSpiralTelegraphStart(FSkylineTorHammerOnSpiralTelegraphData Data){}

	UFUNCTION(BlueprintEvent)
	void OnShieldBreak(FSkylineTorHammerEventHandlerShieldBreakData Data){}

	UFUNCTION(BlueprintEvent)
	void OnBladeHit(FSkylineTorHammerEventHandlerOnBladeHitData Data){}

	UFUNCTION(BlueprintEvent)
	void OnWhirlAttackTelegraphStop(){}

	UFUNCTION(BlueprintEvent)
	void OnWhirlAttackTelegraphStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSwingAttackImpact(FOnSwingAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnSwingAttackAnticipationStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSwingAttackTelegraphStop(){}

	UFUNCTION(BlueprintEvent)
	void OnSwingAttackTelegraphStart(){}

	UFUNCTION(BlueprintEvent)
	void OnShortStunnedStop(){}

	UFUNCTION(BlueprintEvent)
	void OnShortStunnedStart(){}

	UFUNCTION(BlueprintEvent)
	void OnStunnedStop(){}

	UFUNCTION(BlueprintEvent)
	void OnStunnedStart(){}

	UFUNCTION(BlueprintEvent)
	void OnLandStop(){}

	UFUNCTION(BlueprintEvent)
	void OnLandStart(){}

	UFUNCTION(BlueprintEvent)
	void OnImpactLand(FSkylineTorHammerOnHitEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnImpactHit(FSkylineTorHammerOnHitEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnRecover(){}

	UFUNCTION(BlueprintEvent)
	void OnRecallStop(){}

	UFUNCTION(BlueprintEvent)
	void OnRecallStart(FSkylineTorHammerOnRecallEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnAttackHit(FSkylineTorHammerOnAttackHitEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnVolleyThrow(FSkylineTorHammerOnVolleyTelegraphStartData Data){}

	UFUNCTION(BlueprintEvent)
	void OnChargeAttackStop(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeAttackStart(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeAttackTelegraphStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSmashAttackAnticipationStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSwingAttack(){}

	UFUNCTION(BlueprintEvent)
	void OnHitGeneral(FSkylineTorHammerOnHitEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnWhipGrabbedSwing(){}

	/* END OF AUTO-GENERATED CODE */

	ASkylineTorHammer Hammer;
	ASkylineTor MrHammer;

	UFUNCTION(BlueprintEvent)
	void OnGrabbedByWhip(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents) {};

	UFUNCTION(BlueprintEvent)
	void OnReleasedByWhip(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse) {};

	UFUNCTION(BlueprintEvent)
	void OnAttachedToMrHammer() {};

	UFUNCTION(BlueprintEvent)
	void OnDetachedFromMrHammer() {};

	UPROPERTY(BlueprintReadWrite)
	bool bIsStunned = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Hammer = Cast<ASkylineTorHammer>(HazeOwner);
		MrHammer = Cast<ASkylineTor>(Hammer.HammerComp.HoldHammerComp.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hammer.WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbedByWhip");
		Hammer.WhipResponse.OnReleased.AddUFunction(this, n"OnReleasedByWhip");

		MrHammer.HoldHammerComp.OnAttached.AddUFunction(this, n"OnAttachedToMrHammer");
		MrHammer.HoldHammerComp.OnDetached.AddUFunction(this, n"OnDetachedFromMrHammer");

		MrHammer.MoveAudioComp.LinkMovementRequests(Hammer.MoveAudioComp);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Hammer.WhipResponse.OnGrabbed.UnbindObject(this);
		Hammer.WhipResponse.OnReleased.UnbindObject(this);

		if(MrHammer != nullptr)
		{
			MrHammer.HoldHammerComp.OnAttached.UnbindObject(this);
			MrHammer.HoldHammerComp.OnDetached.UnbindObject(this);
		}
	}

	UFUNCTION(BlueprintPure)
	bool HammerBehaviourActivated()
	{
		return MrHammer.PhaseComp.Phase > ESkylineTorPhase::Grounded && !bIsStunned;
	}
}