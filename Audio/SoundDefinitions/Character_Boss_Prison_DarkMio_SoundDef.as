
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ScytheTrailDeactivated(){}

	UFUNCTION(BlueprintEvent)
	void ScytheTrailActivated(){}

	UFUNCTION(BlueprintEvent)
	void MagneticSlamFinalBlast(){}

	UFUNCTION(BlueprintEvent)
	void MagneticSlamBlasted(){}

	UFUNCTION(BlueprintEvent)
	void MagneticSlamExit(){}

	UFUNCTION(BlueprintEvent)
	void MagneticSlamImpact(){}

	UFUNCTION(BlueprintEvent)
	void MagneticSlamEnter(){}

	UFUNCTION(BlueprintEvent)
	void GrabPlayerMagnetBlasted(){}

	UFUNCTION(BlueprintEvent)
	void GrabPlayerStartChoke(){}

	UFUNCTION(BlueprintEvent)
	void GrabPlayerCatch(){}

	UFUNCTION(BlueprintEvent)
	void GrabPlayerEnter(){}

	UFUNCTION(BlueprintEvent)
	void GrabPlayerExit(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter ScytheEmitter;

	UPROPERTY()
	UHazeAudioEmitter SlamAttackTargetEmitter;

	const float MAX_TRACKED_RELATIVE_SCYTHE_SPEED = 3000;
	const float MAX_TRACKED_RELATIVE_SCYTHE_SPEED_DELTA = 500;
	private float CachedScytheMovementSpeed = 0.0;
	private float CachedScytheMovementSpeedDelta = 0.0;
	APrisonBoss DarkMio;

	private FVector PreviousScytheLocation;
	private FVector PreviousDarkMioLocation;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector DarkMioLocation = DarkMio.ActorLocation;
		const FVector ScytheLocation = ScytheEmitter.GetEmitterLocation();

		const FVector DarkMioVelo = DarkMioLocation - PreviousDarkMioLocation;
		const FVector ScytheRelativeMovement = (ScytheLocation - PreviousScytheLocation) - DarkMioVelo;

		const float CurrScytheMovementSpeed = ScytheRelativeMovement.Size() / DeltaSeconds;
		CachedScytheMovementSpeedDelta = CurrScytheMovementSpeed - CachedScytheMovementSpeed;

		CachedScytheMovementSpeed = CurrScytheMovementSpeed;
		PreviousDarkMioLocation = DarkMioLocation;
		PreviousScytheLocation = ScytheLocation;

		if (DarkMio.TargetDangerZone != nullptr)
		{
			SlamAttackTargetEmitter.AudioComponent.SetWorldLocation(DarkMio.TargetDangerZone.ActorLocation);
		}	
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Scythe Movement Speed"))
	float GetRelativeScytheMovementSpeed()
	{
		return Math::Saturate(CachedScytheMovementSpeed / MAX_TRACKED_RELATIVE_SCYTHE_SPEED);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Scythe Movement Speed Delta"))
	float GetRelativeScytheMovementSpeedDelta()
	{
		return Math::Saturate(CachedScytheMovementSpeedDelta / (MAX_TRACKED_RELATIVE_SCYTHE_SPEED_DELTA));
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if (EmitterName == n"SlamAttackTargetEmitter")
		{
			return false;
		}

		return true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void PostCompiled()
	{
		const float StartOffset = 0.0;
		const float EndOffset = 0.0;
		//SoundDefEditor::UpdateDarkMioScytheTrailAnimNotifyStates(this, StartOffset, EndOffset);
	}
#endif

}