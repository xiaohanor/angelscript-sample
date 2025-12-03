
class UCarChaseTetherPlayerComponent : UActorComponent
{
	AHazePlayerCharacter OwningPlayer;
	UCarChaseTetherPlayerSettings Settings;
	ECarChaseTetherPlayerStates State;

	FCarChaseTetherData Data;
	FCarChaseTetherPlayerAnimData AnimData;

	UPROPERTY(Category = Settings)
	UAnimSequence TempAnimation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		Settings = UCarChaseTetherPlayerSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void ActivateTether(UCarChaseTetherPointComponent TetherPoint)
	{
		Data.ActiveTetherPoint = TetherPoint;
	}

	void DeactivateTether()
	{
		Data.ResetData();
	}

	void ConstrainVelocityToTetherPoint(FVector& Velocity, FVector& DeltaMove)
	{
		if(!Data.bTetherTaut)
		{
			//Ease into the swing/tether

			// Don't constrain if you are going towards the tether point
			if (TetherPointToPlayer.DotProduct(Velocity) < 0.0)
				return;

			float SpeedAwayFromPoint = TetherPointToPlayer.GetSafeNormal().DotProduct(Velocity);
			Data.AcceleratedTetherLength.SnapTo(TetherPointToPlayer.Size(), SpeedAwayFromPoint);
			Data.bTetherTaut = true;
		}

		//Remove Velocity in the direction of the tether point
		FVector TetherTension = PlayerToTetherPoint.GetSafeNormal() * PlayerToTetherPoint.GetSafeNormal().DotProduct(Velocity);
		Velocity -= TetherTension;

		//Move the delta around the sphere
		FVector RotationAxis = Velocity.CrossProduct(PlayerToTetherPoint).GetSafeNormal();
		FQuat VelocityRotation = FQuat(RotationAxis, DeltaMove.Size() / Data.TetherLength);

		//Calculate the new location, and ensure the tether is the correct length
		FVector TetherPointToTargetLocation = TetherPointToPlayer.GetSafeNormal() * Data.TetherLength;
		TetherPointToTargetLocation = VelocityRotation * TetherPointToTargetLocation;
		FVector TargetPlayerLocation = TetherPointLocation + TetherPointToTargetLocation;

		DeltaMove = TargetPlayerLocation - PlayerLocation;
		Velocity = VelocityRotation * Velocity;
	}

	bool HasActivatedTetherPoint() const
	{
		return Data.HasValidTetherPoint();
	}

	FVector GetPlayerLocation() const property
	{
		return OwningPlayer.ActorCenterLocation;
	}

	FVector GetTetherPointLocation() const property
	{
		return Data.ActiveTetherPoint.WorldLocation;
	}

	FVector GetTetherPointToPlayer() const property
	{
		return GetPlayerLocation() - GetTetherPointLocation();
	}

	FVector GetPlayerToTetherPoint() const property
	{
		return GetTetherPointLocation() - GetPlayerLocation();
	}

	float GetTetherAngle() const property
	{
		return Math::RadiansToDegrees(PlayerToTetherPoint.AngularDistance(OwningPlayer.ActorForwardVector));
	}
}

struct FCarChaseTetherData
{
	UCarChaseTetherPointComponent ActiveTetherPoint;
	FHazeAcceleratedFloat AcceleratedTetherLength;
	bool bTetherTaut = false;

	float GetTetherLength() const property
	{
		return AcceleratedTetherLength.Value;
	}

	void ResetData()
	{
		ActiveTetherPoint = nullptr;
		bTetherTaut = false;
	}

	bool HasValidTetherPoint() const
	{
		return ActiveTetherPoint != nullptr;
	}

}

struct FCarChaseTetherPlayerAnimData
{

}

enum ECarChaseTetherPlayerStates
{
	Inactive,
	Attaching,
	Swinging,
	Detaching
}

