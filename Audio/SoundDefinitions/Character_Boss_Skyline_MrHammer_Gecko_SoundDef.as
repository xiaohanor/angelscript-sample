
UCLASS(Abstract)
class UCharacter_Boss_Skyline_MrHammer_Gecko_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipThrownImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipThrown(){}

	UFUNCTION(BlueprintEvent)
	void OnBlobAttackLaunchProjectile(FGeckoBlobProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnBlobAttackTelegraph(FGeckoBlobProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnDakkaAttackDone(FGeckoDakkaProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnDakkaAttackBurstEnd(FGeckoDakkaProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnDakkaAttackLaunchProjectile(FGeckoDakkaProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnDakkaAttackBurstStart(FGeckoDakkaProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnDakkaAttackTelegraph(FGeckoDakkaProjectileLaunch Params){}

	UFUNCTION(BlueprintEvent)
	void OnConstrainPlayerEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnConstrainPlayerStart(FSkylineGeckoEffectHandlerOnPounceData Data){}

	UFUNCTION(BlueprintEvent)
	void OnPounceEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnPounceAttackHit(FSkylineGeckoEffectHandlerOnPounceData Data){}

	UFUNCTION(BlueprintEvent)
	void OnPounceLand(){}

	UFUNCTION(BlueprintEvent)
	void OnOverturnedStop(){}

	UFUNCTION(BlueprintEvent)
	void OnOverturnedStart(){}

	UFUNCTION(BlueprintEvent)
	void OnStunnedStop(){}

	UFUNCTION(BlueprintEvent)
	void OnStunnedStart(){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnPreDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnTakeDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipGrabbed(){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphPounce(){}

	UFUNCTION(BlueprintEvent)
	void OnEntryLand(){}

	/* END OF AUTO-GENERATED CODE */

	const float MAX_FORWARD_SPEED = 750;

	UPROPERTY(BlueprintReadOnly)
	AAISkylineGecko Gecko;

	UPROPERTY(BlueprintReadWrite)
	AHazePlayerCharacter PinnedPlayerTarget;

	UFUNCTION(BlueprintEvent)
	void OnGroundedStart() {};

	UFUNCTION(BlueprintEvent)
	void OnGroundedStop() {};
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Gecko = Cast<AAISkylineGecko>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetMovementSpeed()
	{
		return Math::Saturate(Math::Max(Math::Abs(Gecko.AnimComp.SpeedForward), Math::Abs(Gecko.AnimComp.SpeedRight)) / MAX_FORWARD_SPEED);
	}

	UFUNCTION(BlueprintPure)
	float GetPlayerPinnedButtonMashProgress()
	{
		if(PinnedPlayerTarget == nullptr)
			return 0.0;

		return PinnedPlayerTarget.GetButtonMashProgress(SkylineGeckoTags::SkylineGeckoPlayerPinnedInstigatorTag);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const bool bIsGrounded = Gecko.MoveComp.IsOnWalkableGround();
		const bool bGroundedChanged = Gecko.MoveComp.WasOnWalkableGround() != bIsGrounded;
		if(bGroundedChanged)
		{
			if(bIsGrounded)
				OnGroundedStart();
			else
				OnGroundedStop();
		}
	}
}