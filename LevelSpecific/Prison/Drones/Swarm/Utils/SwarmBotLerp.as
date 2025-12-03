enum ESwarmBotLerpType
{
	Relative,
	World
}

class USwarmBotLerp : UObject
{
	ESwarmBotLerpType LerpType;

	FVector LocationStart, LocationTarget;
	FQuat RotationStart, RotationTarget;

	float Duration;
	float Exponent;

	private float ActiveDuration;

	USwarmBotLerp(FVector CurrentLocation, FVector _LocationTarget, FQuat CurrentRotation, FQuat _RotationTarget, float _Duration, float _Exponent)
	{
		LocationStart = CurrentLocation;
		LocationTarget = _LocationTarget;
		RotationStart = CurrentRotation;
		RotationTarget = _RotationTarget;

		Duration = _Duration;
		Exponent = _Exponent;
	}

	FTransform Tick(float DeltaTime)
	{
		ActiveDuration += DeltaTime;

		float Alpha = Math::Pow(Math::Saturate(ActiveDuration / Duration), Exponent);

		FVector Location = Math::Lerp(LocationStart, LocationTarget, Alpha);
		FQuat Rotation = FQuat::FastLerp(RotationStart, RotationTarget, Alpha);

		return FTransform(Rotation, Location);
	}

	bool IsDone() const
	{
		return ActiveDuration >= Duration;
	}
}