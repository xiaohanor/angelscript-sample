event void FIslandPressurePlateSignature();

class AIslandPressurePlate : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;
	
	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FrameMesh;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditAnywhere)
	AIslandOverloadShootablePanel PanelToActivate;

	UPROPERTY(EditAnywhere)
	AIslandOverloadPanelListener PanelListener;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 0.5;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MioOnColor;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MioOffColor;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor ZoeOnColor;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor ZoeOffColor;

	UPROPERTY(EditDefaultsOnly)
	float MioButtonTintMuliplier = 25;

	UPROPERTY(EditDefaultsOnly)
	float ZoeButtonTintMuliplier = 35;

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
	FIslandPressurePlateSignature OnInteractionStarted;

	UPROPERTY()
	FIslandPressurePlateSignature OnInteractionEnd;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface MioBaseMaterial;
	
	UPROPERTY()
	UMaterialInterface ZoeMaterial;
	
	UPROPERTY()
	UMaterialInterface ZoeBaseMaterial;

	UPROPERTY(EditInstanceOnly)
	bool bIsDoubleInteract = false;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = bIsDoubleInteract, EditConditionHides))
	AIslandPressurePlate OtherPressurePlate;

	bool bIsCompleted;
	bool bIsPressed = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ButtonMesh.SetMaterial(0, MioMaterial);
			ButtonMesh.SetMaterial(1, MioBaseMaterial);
			FrameMesh.SetMaterial(0, MioBaseMaterial);
		}
		else
		{
			ButtonMesh.SetMaterial(0, ZoeMaterial);
			ButtonMesh.SetMaterial(1, ZoeBaseMaterial);
			FrameMesh.SetMaterial(0, ZoeBaseMaterial);
		}

		if(bIsDoubleInteract
		&& OtherPressurePlate != nullptr)
		{
			OtherPressurePlate.OtherPressurePlate = this;
			OtherPressurePlate.bIsDoubleInteract = true;
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

		CollisionBox.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		CollisionBox.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		if (PanelToActivate != nullptr)
		{
			PanelToActivate.OnCompleted.AddUFunction(this, n"HandlePanelCompleted");
			PanelToActivate.DisablePanel();
		}

		if (PanelListener != nullptr)
			PanelListener.OnCompleted.AddUFunction(this, n"HandleListenerCompleted");

	}

	
	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bIsCompleted)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != Game::GetPlayer(UsableByPlayer))
			return;

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			FLinearColor NewColor = FLinearColor(0.3, 0, 0, 1) * MioButtonTintMuliplier;
			ButtonMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", MioOnColor);
			// ButtonMesh.SetMaterial(1, MioActiveMaterial);
		}
		else
		{
			FLinearColor NewColor = FLinearColor(0, 0.2, 0.3, 1) * ZoeButtonTintMuliplier;
			ButtonMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", ZoeOnColor);
			// ButtonMesh.SetMaterial(1, ZoeActiveMaterial);
		}

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback(Player);

		if (PanelToActivate != nullptr)
		{
			if(bIsDoubleInteract
			&& OtherPressurePlate != nullptr)
			{
				if(OtherPressurePlate.bIsPressed)
				{
					PanelToActivate.EnablePanel();
					OtherPressurePlate.PanelToActivate.EnablePanel();
				}
			}
			else
			{
				PanelToActivate.EnablePanel();
			}
		}

		bIsPressed = true;
		OnInteractionStarted.Broadcast();
		Start();
		UIslandPressurePlateEffectHandler::Trigger_OnPressed(this);
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	
		if (bIsCompleted)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != Game::GetPlayer(UsableByPlayer))
			return;

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			FLinearColor NewColor = FLinearColor(1, 0, 0, 1);
			ButtonMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", MioOffColor);
			// ButtonMesh.SetMaterial(1, MioMaterial);
		}
		else
		{
			FLinearColor NewColor = FLinearColor(0, 0.2, 0.3, 1);
			ButtonMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveTint", ZoeOffColor);
			// ButtonMesh.SetMaterial(1, ZoeMaterial);
		}

		if (PanelToActivate != nullptr)
		{
			if(bIsDoubleInteract
			&& OtherPressurePlate != nullptr)
			{
				PanelToActivate.DisablePanel();
				OtherPressurePlate.PanelToActivate.DisablePanel();
			}
			else
			{
				PanelToActivate.DisablePanel();
			}
		}

		bIsPressed = false;
		OnInteractionEnd.Broadcast();
		Reverse();
		UIslandPressurePlateEffectHandler::Trigger_OnUnpressed(this);
	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.Play();
	}

	UFUNCTION()
	void Reverse()
	{
		if (!bIsCompleted)
			MoveAnimation.Reverse();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		MovableComp.SetRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		MovableComp.SetRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		//SetActorRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		//SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	
	UFUNCTION()
	void OnFinished()
	{


	}

	UFUNCTION()
	void HandlePanelCompleted()
	{
		if (PanelListener != nullptr)
			return;

		if (bIsResettable)
			return;

		bIsCompleted = true;
		MoveAnimation.Play();

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ButtonMesh.SetMaterial(1, MioMaterial);
		}
		else
		{
			ButtonMesh.SetMaterial(1, ZoeMaterial);
		}
	}

	UFUNCTION()
	void HandleListenerCompleted()
	{
		if (bIsResettable)
			return;
		
		bIsCompleted = true;
		MoveAnimation.Play();

		if (PanelToActivate != nullptr)
			PanelToActivate.DisablePanel();

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ButtonMesh.SetMaterial(1, MioMaterial);
		}
		else
		{
			ButtonMesh.SetMaterial(1, ZoeMaterial);
		}
	}


}

UCLASS(Abstract)
class UIslandPressurePlateEffectHandler : UHazeEffectEventHandler
{
	// Triggers when the pressure plate is pressed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPressed() {}

	// Triggers when the pressure plate is unpressed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnpressed() {}
}