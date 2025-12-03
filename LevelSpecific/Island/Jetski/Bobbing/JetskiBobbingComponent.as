class UJetskiBobbingComponent : UActorComponent
{
	private AJetski Jetski;

	FHazeAcceleratedFloat AccRoll;
	FHazeAcceleratedFloat AccPitch;

	FRotator RelativeOffsetFromImpact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("AccRoll;Value", AccRoll.Value)
			.Value("AccRoll;Velocity", AccRoll.Velocity)

			.Value("AccPitch;Value", AccPitch.Value)
			.Value("AccPitch;Velocity", AccPitch.Velocity)
		;
#endif
	}

	void ApplyLocationAndRotation()
	{
		if(HasControl())
		{
			FRotator RelativeRotation;
			RelativeRotation.Roll = -AccRoll.Value;
			RelativeRotation.Pitch = AccPitch.Value;

			RelativeRotation += RelativeOffsetFromImpact;

			Jetski.SyncedMeshPivotRotationComp.SetValue(RelativeRotation);
		}

		Jetski.MeshPivot.SetRelativeRotation(Jetski.SyncedMeshPivotRotationComp.Value);
	}

	void AddBobbingImpulse(FVector Impulse)
	{
		FVector Right = -FVector::UpVector.CrossProduct(Impulse).GetSafeNormal();
		FVector AngularImpulse = Right * Impulse.Size();

		AddBobbingAngularImpulse(AngularImpulse);
	}

	void AddBobbingAngularImpulse(FVector AngularImpulse)
	{
		TEMPORAL_LOG(this)
			.Event(f"Added Angular Impulse {AngularImpulse}")
			.DirectionalArrow("AngularImpulse", Owner.ActorLocation, AngularImpulse)
		;

		float RollImpulse = AngularImpulse.DotProduct(Jetski.ActorForwardVector);
		float PitchImpulse = AngularImpulse.DotProduct(Jetski.ActorRightVector);

		AccRoll.Velocity += RollImpulse;
		AccPitch.Velocity += PitchImpulse;

		AccRoll.Velocity = GetClampedRollVelocity(AccRoll.Velocity);
		AccPitch.Velocity = GetClampedPitchVelocity(AccPitch.Velocity);
	}

	float GetClampedRoll(float Roll)
	{
		return Math::Clamp(Roll, -Jetski.Settings.BobbingMaxRoll, Jetski.Settings.BobbingMaxRoll);
	}

	float GetClampedRollVelocity(float RollVelocity)
	{
		return Math::Clamp(RollVelocity, -Jetski.Settings.BobbingWaterImpactRollMaxVelocity, Jetski.Settings.BobbingWaterImpactRollMaxVelocity);
	}

	float GetClampedPitch(float Pitch)
	{
		return Math::Clamp(Pitch, -Jetski.Settings.BobbingMaxPitch, Jetski.Settings.BobbingMaxPitch);
	}

	float GetClampedPitchVelocity(float PitchVelocity)
	{
		return Math::Clamp(PitchVelocity, -Jetski.Settings.BobbingWaterImpactPitchMaxVelocity, Jetski.Settings.BobbingWaterImpactPitchMaxVelocity);
	}
};

mixin void AddBobbingImpulse(AJetski Jetski, FVector Impulse)
{
	Jetski.BobbingComponent.AddBobbingImpulse(Impulse);
}

mixin void AddBobbingAngularImpulse(AJetski Jetski, FVector AngularImpulse)
{
	Jetski.BobbingComponent.AddBobbingAngularImpulse(AngularImpulse);
}