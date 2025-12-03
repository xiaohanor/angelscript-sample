event void FSkylinePhoneGameSignature();

class ASkylinePhoneGame : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent GameBounds;
	default GameBounds.bGenerateOverlapEvents = false;
	default GameBounds.CollisionProfileName = n"NoCollision";
	default GameBounds.BoxExtent = FVector(10.0, 90.0, 160.0);	

	UPROPERTY(DefaultComponent)
	USceneComponent InputPivot;

	UPROPERTY(DefaultComponent, Attach = InputPivot)
	USceneComponent InputPointer;

	float InputRadius = 1.0;

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCapture;
	default SceneCapture.ProjectionType = ECameraProjectionMode::Perspective;
	default SceneCapture.OrthoWidth = 180.0;
	default SceneCapture.bCaptureEveryFrame = false;
	default SceneCapture.bCaptureOnMovement = false;
	default SceneCapture.RelativeLocation = FVector::ForwardVector * -100.0;

	UPROPERTY(EditDefaultsOnly, Category = "Phone Game")
	bool bShowCursor = true;

	FVector2D Input;
	FVector2D CursorPosition;

	USkylinePhoneGameButtonComponent ActiveButton;

	FSkylinePhoneGameSignature OnPhoneGameEnd;
	FSkylinePhoneGameSignature OnPhoneGameRestart;
	FSkylinePhoneGameSignature OnPhoneCall;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		InputPointer.RelativeLocation = FVector(0.0, CursorPosition.X, CursorPosition.Y);
		SceneCapture.CaptureScene();
	}

	UFUNCTION()
	void EndPhoneGame()
	{
		OnPhoneGameEnd.Broadcast();
	}

	UFUNCTION()
	void RestartPhoneGame()
	{
		OnPhoneGameRestart.Broadcast();
	}

	UFUNCTION()
	private void HandleClickPressed()
	{
		auto Trace = Trace::InitObjectType(EObjectTypeQuery::WorldDynamic);
		Trace.UseSphereShape(InputRadius);
		auto Overlaps = Trace.QueryOverlaps(InputPointer.WorldLocation);

		for (auto Overlap : Overlaps)
		{
			auto Button = Cast<USkylinePhoneGameButtonComponent>(Overlap.Component);
			if (Button != nullptr)
			{
				ActiveButton = Button;
				Button.OnButtonPressed.Broadcast();
			}
		}

		BP_ClickPressed();
	}

	UFUNCTION()
	private void HandleClickReleased()
	{
		if (ActiveButton != nullptr)
			ActiveButton.OnButtonReleased.Broadcast();

		ActiveButton = nullptr;

		BP_ClickReleased();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ClickPressed()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_ClickReleased()
	{}
};