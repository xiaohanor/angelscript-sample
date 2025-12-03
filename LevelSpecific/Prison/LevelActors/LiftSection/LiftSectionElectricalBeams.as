UCLASS(Abstract)
class ALiftSectionElectricalBeams : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	UNiagaraComponent Beam;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	UNiagaraComponent Beam2;
	UPROPERTY(DefaultComponent)
	USceneComponent MainMoveRoot;
	UPROPERTY(DefaultComponent)
	USceneComponent MainMoveLocation;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	UStaticMeshComponent StaticMesh;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	UStaticMeshComponent StaticMesh2;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	USceneComponent SubMoveRoot;
	UPROPERTY(DefaultComponent, Attach = SubMoveRoot)
	UStaticMeshComponent StaticMeshDivider1;
	UPROPERTY(DefaultComponent, Attach = SubMoveRoot)
	UStaticMeshComponent StaticMeshDivider2;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	USceneComponent ElectricalBeamStartLoc1;
	UPROPERTY(DefaultComponent, Attach = MainMoveRoot)
	USceneComponent ElectricalBeamStartLoc2;
	UPROPERTY(DefaultComponent, Attach = SubMoveRoot)
	USceneComponent ElectricalBeamEndLoc1;
	UPROPERTY(DefaultComponent, Attach = SubMoveRoot)
	USceneComponent ElectricalBeamEndLoc2;

	default SetActorHiddenInGame(true);

	FHazeAcceleratedFloat AcceleratedFloatY;
	FHazeAcceleratedFloat AcceleratedFloatX;
	float TargetLocation;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript(){}

	UPROPERTY(EditAnywhere)
	bool bIsActive = false;
	float SpeedMultipier = 1;
	float UpDownSpeedMultipier = 1;
	bool bMoveUpDown = false;
	bool bIsMovingUp = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedFloatY.Value = MainMoveRoot.GetRelativeLocation().Y;
		AcceleratedFloatX.Value = SubMoveRoot.GetRelativeLocation().X;
		TargetLocation = MainMoveLocation.GetRelativeLocation().Y;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsActive == false)
			return;

		TargetLocation = MainMoveLocation.GetRelativeLocation().Y;
		AcceleratedFloatY.SpringTo(TargetLocation, 0.2 * SpeedMultipier, 0.9, DeltaTime);
		MainMoveRoot.SetRelativeLocation(FVector(0, AcceleratedFloatY.Value, 0));

		Beam.SetNiagaraVariableVec3("BeamEnd", FVector(ElectricalBeamEndLoc1.GetWorldLocation()));
		Beam2.SetNiagaraVariableVec3("BeamEnd", FVector(ElectricalBeamEndLoc2.GetWorldLocation()));
		Beam.SetNiagaraVariableVec3("BeamStart", FVector(ElectricalBeamStartLoc1.GetWorldLocation()));
		Beam2.SetNiagaraVariableVec3("BeamStart", FVector(ElectricalBeamStartLoc2.GetWorldLocation()));
		//Debug::DrawDebugSphere(StaticMeshDivider1.GetWorldLocation(), 200);
		//Debug::DrawDebugSphere(StaticMeshDivider2.GetWorldLocation(), 200);

		if (Math::IsNearlyEqual(AcceleratedFloatY.Value, TargetLocation, 500.0))
		{
			StopElectricalBeam();
		}
		
		if(bMoveUpDown == false)
			return;
		
		SubMoveRoot.SetRelativeLocation(FVector(AcceleratedFloatX.Value, 0,0));

		if(bIsMovingUp)
		{
			AcceleratedFloatX.SpringTo(800, 0.2 * UpDownSpeedMultipier, 0.8, DeltaTime);
			if(Math::IsNearlyEqual(AcceleratedFloatX.Value, 800, 50.0))
			{
				bIsMovingUp = false;
			}
		}
		else
		{
			AcceleratedFloatX.SpringTo(-800, 0.2 * UpDownSpeedMultipier, 0.8, DeltaTime);
			if(Math::IsNearlyEqual(AcceleratedFloatX.Value, -800, 50.0))
			{
				bIsMovingUp = true;
			}
		}
	}

	UFUNCTION()
	void StartElecticalBeam(float BeamGapLocation, float MovementSpeedMultiplier, bool MoveUpDown, float UpDownSpeedMultiplier)
	{
		
		if(MovementSpeedMultiplier > 0)
			SpeedMultipier = MovementSpeedMultiplier;
		if(UpDownSpeedMultiplier > 0)
			UpDownSpeedMultipier = UpDownSpeedMultiplier;
		
		SetActorHiddenInGame(false);
		SubMoveRoot.SetRelativeLocation(FVector(BeamGapLocation, 0,0));
		AcceleratedFloatX.Value = SubMoveRoot.GetRelativeLocation().X;
		bIsActive = true;
		bMoveUpDown = MoveUpDown;
	}
	UFUNCTION()
	void StopElectricalBeam()
	{
		SetActorHiddenInGame(true);
		bIsActive = false;
		bMoveUpDown = false;
	}
}