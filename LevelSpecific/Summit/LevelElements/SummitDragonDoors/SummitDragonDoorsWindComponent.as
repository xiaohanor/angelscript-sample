enum ESummitDragonDoorWindAxisAffected
{
	Both,
	XAxis,
	YAxis
}

class USummitDragonDoorsWindComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitDragonDoors Door;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ESummitDragonDoorWindAxisAffected AFfectedAxis;

	FVector StartingScale;
	ASummitAirCurrent AirCurrent;

	bool bWindCurrentAllowed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AirCurrent = Cast<ASummitAirCurrent>(Owner);

		if (Door != nullptr)
		{
			StartingScale = Owner.ActorScale3D;

			if (Door.IsDoorClosed())
			{
				bWindCurrentAllowed = false;
				AirCurrent.WindCurrentSystem.Deactivate();
				AirCurrent.AddDisabler(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float XScale = StartingScale.X * Door.GetOpenedPercentage();
		float YScale = StartingScale.Y * Door.GetOpenedPercentage();
		FVector CurrentScale;

		switch (AFfectedAxis)
		{
			case ESummitDragonDoorWindAxisAffected::Both:
				CurrentScale = FVector(XScale, YScale, StartingScale.Z);
			break;

			case ESummitDragonDoorWindAxisAffected::XAxis:
				CurrentScale = FVector(XScale, StartingScale.Y, StartingScale.Z);
			break;

			case ESummitDragonDoorWindAxisAffected::YAxis:
				CurrentScale = FVector(StartingScale.X, YScale, StartingScale.Z);
			break;
		}

		if (Door.IsDoorClosed() && bWindCurrentAllowed)
		{
			AirCurrent.WindCurrentSystem.Deactivate();
			AirCurrent.AddDisabler(this);
			bWindCurrentAllowed = false;
		}
		else if (!Door.IsDoorClosed() && !bWindCurrentAllowed)
		{
			AirCurrent.WindCurrentSystem.Activate();
			AirCurrent.RemoveDisabler(this);
			bWindCurrentAllowed = true;
		}

		Owner.SetActorScale3D(CurrentScale);
	}
}