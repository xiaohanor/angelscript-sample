struct FSkylineEnforcerVOAssetData
{
	// UPROPERTY(BlueprintReadOnly)
	// UHazeVoxAsset
}


UCLASS(Abstract)
class UVO_COM_Skyline_Shared_EnforcerBasic_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipThrowImpact(FEnforcerEffectOnGravityWhipThrowImpactData EnforcerEffectOnGravityWhipThrowImpactData){}

	UFUNCTION(BlueprintEvent)
	void OnBladeHit(FEnforcerEffectOnBladeHitData EnforcerEffectOnBladeHitData){}

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipGrabbed(){}

	UFUNCTION(BlueprintEvent)
	void OnForceFieldRestore(){}

	UFUNCTION(BlueprintEvent)
	void OnForceFieldBreak(){}

	UFUNCTION(BlueprintEvent)
	void OnAdvance(){}

	UFUNCTION(BlueprintEvent)
	void OnBreakArmor(){}

	UFUNCTION(BlueprintEvent)
	void OnShotFired(){}

	UFUNCTION(BlueprintEvent)
	void OnTakeDamage(){}

	UFUNCTION(BlueprintEvent)
	void OnTargetLost(){}

	UFUNCTION(BlueprintEvent)
	void OnTargetSighted(){}

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipThrown(){}

	UFUNCTION(BlueprintEvent)
	void OnRespawn(){}

	UFUNCTION(BlueprintEvent)
	void OnUnspawn(){}

	UFUNCTION(BlueprintEvent)
	void OnReloadComplete(){}

	UFUNCTION(BlueprintEvent)
	void OnReload(FEnforcerEffectOnReloadData EnforcerEffectOnReloadData){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphShooting(FEnforcerEffectOnTelegraphData EnforcerEffectOnTelegraphData){}

	UFUNCTION(BlueprintEvent)
	void OnPostFire(){}

	UFUNCTION(BlueprintEvent)
	void OnRagdoll(){}

	UFUNCTION(BlueprintEvent)
	void OnGloryDeathStart(){}

	UFUNCTION(BlueprintEvent)
	void OnGotYourBackResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnTestResponse(FTestVOSomethingParams TestVOSomethingParams){}

	UFUNCTION(BlueprintEvent)
	void OnAffirmativeResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnAdvanceResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnDeathFriendlyBackupRequestResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnDeathFriendlyResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnPanicBackupRequestResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnPanicResponse(){}

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipStumble(){}

	UFUNCTION(BlueprintEvent)
	void OnBladeResist(FEnforcerEffectOnBladeResistData EnforcerEffectOnBladeResistData){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(FEnforcerEffectOnDeathData EnforcerEffectOnDeathData){}

	UFUNCTION(BlueprintEvent)
	void OnAreaAttackImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnPostGrenadeThrown(){}

	UFUNCTION(BlueprintEvent)
	void OnThrowGrenade(FEnforcerEffectOnThrowGrenadeData EnforcerEffectOnThrowGrenadeData){}

	UFUNCTION(BlueprintEvent)
	void OnWieldGrenade(FEnforcerEffectOnThrowGrenadeData EnforcerEffectOnThrowGrenadeData){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphThrowGrenade(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeAttackHadMiss(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeAttackHadHit(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeAttackImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeAttackStop(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeAttackStart(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeApproachStop(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeMeleeApproachStart(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	TMap<int, FSkylineEnforcerVOAssetData> EnforcerVODatas;


	// Adding functions for response-logic, so that a response on f.ex. closest friendly trigger an effect event.
	UFUNCTION(BlueprintCallable)
	void TriggerGotYourBackResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnGotYourBackResponse(Responder);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerAffirmativeResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnAffirmativeResponse(Responder);
	}
	
	UFUNCTION(BlueprintCallable)
	void TriggerAdvanceResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnAdvanceResponse(Responder);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerPanicResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnPanicResponse(Responder);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerPanicBackupRequestResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnPanicBackupRequestResponse(Responder);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerDeathFriendlyResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnDeathFriendlyResponse(Responder);
	}

UFUNCTION(BlueprintCallable)
	void TriggerDeathFriendlyBackupRequestResponse(AHazeActor Responder)
	{
		UEnforcerEffectHandler::Trigger_OnDeathFriendlyBackupRequestResponse(Responder);
	}


/* 	UFUNCTION(BlueprintCallable) // if paramaters are needed to send with the event effect
	void TriggerTestResponseCopyParams(AHazeActor Responder, float Test)
	{	// copies the param in to a struct below 
		FTestVOSomethingParams Params;
		Params.TestFloat = Test;
		UEnforcerEffectHandler::Trigger_OnTestResponse(Responder, Params);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerTestResponseNeedToSplitStruct(AHazeActor Responder, FTestVOSomethingParams Params)
	{	// in blueprint we need to split the params pin
		UEnforcerEffectHandler::Trigger_OnTestResponse(Responder, Params);
	} */
}