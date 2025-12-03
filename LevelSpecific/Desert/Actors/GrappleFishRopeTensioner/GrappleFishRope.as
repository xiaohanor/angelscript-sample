class ADesertSharkRope : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeTEMPCableComponent CableComp;

	UPROPERTY(EditInstanceOnly)
	ADesertGrappleFish GrappleFish;

	UPROPERTY(EditInstanceOnly)
	AGrappleFishRopeTensioner RopeTensioner;

	FHazeAcceleratedFloat AccCableLength;

	bool bPull;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CableComp.SetAttachEndToComponent(GrappleFish.SharkMesh, n"Spine");
		CableComp.CableLength = GrappleFish.GetDistanceTo(this) - 400;

		RopeTensioner.OnStarted.AddUFunction(this, n"Started");
		RopeTensioner.OnCompleted.AddUFunction(this, n"Completed");
	}

	UFUNCTION()
	void Detach()
	{
		CableComp.SetAttachEndToComponent(nullptr);
		bPull = false;
	}

	UFUNCTION()
	private void Completed()
	{
		bPull = false;
		// GrappleFish.EnableMounting();
		// GrappleFish.State.Clear(this);
	}

	UFUNCTION()
	private void Started()
	{
		bPull = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Distance = GrappleFish.GetDistanceTo(this);
		float TautRopeLength = Distance - 2000;
		float LooseRopeLength = Distance - 800;
		float TargetRopeLength = LooseRopeLength;
		if (bPull)
		{
			TargetRopeLength = TautRopeLength;
			CableComp.CableGravityScale = 4;
			CableComp.bEnableStiffness = true;

		}
		else
		{
			CableComp.CableGravityScale = 3;
			CableComp.bEnableStiffness = true;
			CableComp.CableFriction = 1.0;
		}
		AccCableLength.AccelerateTo(TargetRopeLength, 0.25, DeltaSeconds);

		CableComp.CableLength = AccCableLength.Value;
	}
}