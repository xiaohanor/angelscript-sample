
UCLASS(Abstract)
class UGameplay_Character_Boss_Prison_PinballBoss_Ball_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnMagnetDroneAttractKnockback(FOnMagnetDroneAttachedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnKnockedOut(){}

	UFUNCTION(BlueprintEvent)
	void StopLaunch(){}

	UFUNCTION(BlueprintEvent)
	void StartLaunch(){}

	UFUNCTION(BlueprintEvent)
	void OnLaunched(FPinballOnLaunchedEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	APinballBossBall BossBall;
	private bool bWasGrounded = false;

	UFUNCTION(BlueprintEvent)
	void OnStartGrounded(float Intensity) {};

	UFUNCTION(BlueprintEvent)
	void OnStopGrounded() {};

	FRotator PreviousRotation;
	float RotationSpeed;
	const float MAX_ROLL_SPEED = 0.5;
	const float MAX_IMPACT_SPEED = 1000;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BossBall = Cast<APinballBossBall>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const bool bIsGrounded = BossBall.MoveComp.HasGroundContact();
		if(bIsGrounded && !bWasGrounded)
		{
			const float Intensity = Math::Saturate(BossBall.MoveComp.PreviousVelocity.Size() / MAX_IMPACT_SPEED);	
			OnStartGrounded(Intensity);
		}
		else if(!bIsGrounded && bWasGrounded)
			OnStopGrounded();

		bWasGrounded = bIsGrounded;

		const FRotator Rotation = BossBall.ActorRotation;
		RotationSpeed = (Rotation.Quaternion().AngularDistance(PreviousRotation.Quaternion())) / DeltaSeconds;

		PreviousRotation = Rotation;

		float X;
		float _Y;
		FVector2D Previous;
		Audio::GetScreenPositionRelativePanningValue(BossBall.ActorLocation, Previous, X, _Y);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Rolling Speed"))
	float GetRollingSpeed()
	{
		return Math::Saturate(RotationSpeed / MAX_ROLL_SPEED);
	}
}