event void FIslandPressurePlateConnectorSignature();

class AIslandPressurePlateConnector : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;
	
	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent ConnectorMesh;

	UPROPERTY(EditAnywhere)
	AIslandPressurePlate PressurePlateRef;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 0.5;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditInstanceOnly)
	bool bIsResettable;

	UPROPERTY()
	FIslandPressurePlateConnectorSignature OnInteractionStarted;

	UPROPERTY()
	FIslandPressurePlateConnectorSignature OnInteractionEnd;

	UPROPERTY()
	UMaterialInterface MioMaterial;
	
	UPROPERTY()
	UMaterialInterface MioActiveMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface ZoeActiveMaterial;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ConnectorMesh.SetMaterial(0, MioMaterial);
		}
		else
		{
			ConnectorMesh.SetMaterial(0, ZoeMaterial);
		}

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetRelativeTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetRelativeTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (PressurePlateRef == nullptr)
			return;

		PressurePlateRef.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		PressurePlateRef.OnInteractionEnd.AddUFunction(this, n"HandleInteractionEnd");

	}

	UFUNCTION()
	void HandleInteractionStarted()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ConnectorMesh.SetMaterial(0, MioActiveMaterial);
		}
		else
		{
			ConnectorMesh.SetMaterial(0, ZoeActiveMaterial);
		}
	}
	
	UFUNCTION()
	void HandleInteractionEnd()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ConnectorMesh.SetMaterial(0, MioMaterial);
		}
		else
		{
			ConnectorMesh.SetMaterial(0, ZoeMaterial);
		}
	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.Play();
	}

	UFUNCTION()
	void Reverse()
	{
		MoveAnimation.Reverse();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		SetActorRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	
	UFUNCTION()
	void OnFinished()
	{


	}



}