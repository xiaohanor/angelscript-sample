class USanctuaryBossHeartBeatComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float Scale = 3.5;

	UPROPERTY(EditAnywhere)
	float Freq = 6.0;

	UPROPERTY(EditAnywhere)
	float Offset = 0.0;

	FVector InitialScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialScale = Owner.ActorScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha;
		Alpha = (Math::Sin((Time::GameTimeSeconds + Offset) * Freq) + 1.0) * 0.5;
		Alpha = Alpha * Alpha; // * Alpha * Alpha;
		Owner.ActorScale3D = InitialScale + FVector(Scale * Alpha);
	}
};