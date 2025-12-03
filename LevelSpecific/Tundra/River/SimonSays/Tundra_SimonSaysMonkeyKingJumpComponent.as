class UTundra_SimonSaysMonkeyKingJumpComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float JumpHeight = 200.0;
	
	// If you want the monkey king to land slightly later or earlier than the beat.
	UPROPERTY(EditAnywhere)
	float TimeOffset = 0.0;

	/* Both x and y should be within the 0->1 range. */
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(0.5, 1.0);
	default MoveCurve.AddDefaultKey(1.0, 0.0);

	FVector OriginalLocation;
	ATundra_SimonSaysManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalLocation = Owner.ActorLocation;
		Manager = TundraSimonSays::GetManager();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TimeAlpha = 1.0 - Math::Fmod(Manager.GetActiveDuration() + TimeOffset, Manager.GetRealTimeBetweenBeats()) / Manager.GetRealTimeBetweenBeats();

		float MoveAlpha = MoveCurve.GetFloatValue(TimeAlpha);
		Owner.ActorLocation = Math::Lerp(OriginalLocation, OriginalLocation + FVector::UpVector * JumpHeight, MoveAlpha);
	}
}