UCLASS(NotBlueprintable)
class UDentistToothDoubleCannonComponent : UActorComponent
{
	private AHazePlayerCharacter Player;
	UDentistToothDoubleCannonSettings Settings;

	private ADentistDoubleCannon Cannon;
	private bool bIsLaunched = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UDentistToothDoubleCannonSettings::GetSettings(Player);
	}

	void EnterCannon(ADentistDoubleCannon InCannon)
	{
		Cannon = InCannon;
	}

	bool IsInCannon() const
	{
		if(Cannon == nullptr)
			return false;

		if(IsLaunched())
			return false;

		return true;
	}

	ADentistDoubleCannon GetCannon() const
	{
		return Cannon;
	}

	void Launch()
	{
		bIsLaunched = true;
	}

	bool IsLaunched() const
	{
		return bIsLaunched;
	}

	bool ShouldBeDetached() const
	{
		return Cannon.GetPredictedTimeSinceLaunchStart() > Cannon.GetDetachTime();
	}

	FTraversalTrajectory GetLaunchTrajectory() const
	{
		return GetCannon().GetLaunchTrajectory();
	}

	FTransform GetCurrentLaunchTransform() const
	{
		FTransform Transform = Cannon.GetCurrentPlayerTransform(Player.Player, false);
		
		FVector MeshOffsetFromActor = Player.ActorTransform.InverseTransformPositionNoScale(Player.CapsuleComponent.WorldLocation);
		FVector Target = Transform.TransformPositionNoScale(MeshOffsetFromActor);
		Target -= FVector(0, 0, Dentist::CollisionRadius);
		Transform.SetLocation(Target);

		return Transform;
	}

	bool IsCannonStateActive(EDentistDoubleCannonState InState) const
	{
		check(IsInCannon());
		return Cannon.IsStateActive(InState);
	}

	void Reset()
	{
		Cannon = nullptr;
		bIsLaunched = false;
	}
};