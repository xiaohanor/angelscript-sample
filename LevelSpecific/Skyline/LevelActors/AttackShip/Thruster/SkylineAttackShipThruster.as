UCLASS(Abstract)
class ASkylineAttackShipThruster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ThrusterPivot;

	UPROPERTY(DefaultComponent, Attach = ThrusterPivot)
	UStaticMeshComponent ThrusterMeshComp;

	UPROPERTY(DefaultComponent, Attach = ThrusterPivot)
	UNiagaraComponent ThrusterNiagaraComp;

	UPROPERTY(EditAnywhere)
	bool bIsLeft = true;

	/**
	 * How much to turn based on the ship accelerating/decelerating forward.
	 */
	UPROPERTY(EditAnywhere)
	float ForwardAccelerationMultiplier = 5;

	/**
	 * How much to turn based on the current velocity forward.
	 */
	UPROPERTY(EditAnywhere)
	float ForwardVelocityMultiplier = 0.05;

	/**
	 * How much to turn based on the ship rotating.
	 */
	UPROPERTY(EditAnywhere)
	float AngularVelocityMultiplier = 100;

	UPROPERTY(EditAnywhere)
	float MaxAngle = 45;

	UPROPERTY(EditAnywhere)
	float AccelerateDuration = 2;

	UHazeRawVelocityTrackerComponent VelocityTrackerComp;
	FHazeAcceleratedFloat AccAngle;
	FVector PreviousVelocity;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(AttachParentActor == nullptr)
			return;

		if(VelocityTrackerComp == nullptr)
		{
			VelocityTrackerComp = UHazeRawVelocityTrackerComponent::GetOrCreate(AttachParentActor);
		}

		FVector CurrentVelocity = VelocityTrackerComp.CurrentFrameTranslationVelocity;
		if(CurrentVelocity.IsZero())
			CurrentVelocity = VelocityTrackerComp.LastFrameTranslationVelocity;

		FVector Jolt = (CurrentVelocity - PreviousVelocity);
		const float ForwardJolt = Jolt.DotProduct(ActorForwardVector);
		
		const float ForwardSpeed = CurrentVelocity.DotProduct(ActorForwardVector);

		FRotator AngularVelocity = VelocityTrackerComp.CurrentFrameDeltaRotation;
		if(AngularVelocity.IsZero())
			AngularVelocity = VelocityTrackerComp.LastFrameDeltaRotation;
		
		float AngularSpeed = Math::Abs(AngularVelocity.Quaternion().GetTwistAngle(ActorUpVector)) / DeltaSeconds;
		if(bIsLeft)
			AngularSpeed *= -1;

		float TargetAngle = 0;
		TargetAngle += ForwardJolt * ForwardAccelerationMultiplier;
		TargetAngle += ForwardSpeed * ForwardVelocityMultiplier;
		TargetAngle += AngularSpeed * AngularVelocityMultiplier;

		// PrintToScreen(f"{AttachParentActor.Name} ForwardJolt = {ForwardJolt * ForwardAccelerationMultiplier}");
		// PrintToScreen(f"{AttachParentActor.Name} ForwardSpeed = {ForwardSpeed * ForwardVelocityMultiplier}");
		// PrintToScreen(f"{AttachParentActor.Name} AngularSpeed = {AngularSpeed * AngularVelocityMultiplier}");

		TargetAngle = Math::Clamp(TargetAngle, -MaxAngle, MaxAngle);

		AccAngle.AccelerateTo(TargetAngle, AccelerateDuration, DeltaSeconds);
		SetActorRelativeRotation(FQuat(FVector::RightVector, Math::DegreesToRadians(AccAngle.Value)));

		PreviousVelocity = CurrentVelocity;
	}
};