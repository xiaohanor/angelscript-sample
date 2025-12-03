
UCLASS(Abstract)
class ASkylinePhone : ASkylinePhoneBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent InputPivot;

	UPROPERTY(EditDefaultsOnly)
	UTextureRenderTarget2D RenderTarget;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylinePhoneCursor> CursorClass;

	UPROPERTY(EditInstanceOnly)
	ASkylinePhoneProgressSpline SplineActor;
	float SplineLength;

	UPROPERTY(NotEditable)
	float TimeLeft;

	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<ASkylinePhoneGame>> PhoneGames;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylinePhoneGamePhoneCall> PhoneCall;

	ASkylinePhoneGame CurrentGame;
	ASkylinePhoneCursor Cursor;

	bool bPhoneCalled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineActor = TListedActors<ASkylinePhoneProgressSpline>().GetSingle();

		SetActorTickEnabled(false);

		PhoneGameIndex = Save::GetPersistentProfileCounter(n"PhoneGameProgress", -1);

		NextPhoneGame();

		SplineLength = SplineActor.Spline.SplineLength;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentGame != nullptr)
		{
			CurrentGame.CursorPosition = CursorPosition.Value;
		}

		if (SplineActor != nullptr && !bPhoneCompleted)
		{
			TimeLeft = (SplineLength - SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation)) * 0.0002;
		}

#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("CurrentGame", CurrentGame)
		;
#endif
	}

	void NextPhoneGame()
	{
		if (PhoneGameIndex > PhoneGames.Num() - 1)
			return;

		PhoneGameIndex++;
		auto PhoneGame = SpawnActor(PhoneGames[PhoneGameIndex]);

		SetPhoneGame(PhoneGame);
	}

	void SetPhoneGame(ASkylinePhoneGame PhoneGame)
	{
		if(Cursor != nullptr)
		{
			Cursor.DestroyActor();
			Cursor = nullptr;
		}

		if (CurrentGame != nullptr)
		{
			OnClickPressed.UnbindObject(CurrentGame);
			OnClickReleased.UnbindObject(CurrentGame);
			CurrentGame.OnPhoneGameEnd.UnbindObject(this);
			CurrentGame.DestroyActor();
			CurrentGame = nullptr;
		}

		if(PhoneGame.bShowCursor)
		{
			Cursor = SpawnActor(CursorClass);
			Cursor.AttachToComponent(PhoneGame.InputPointer, NAME_None, EAttachmentRule::SnapToTarget);

			OnClickPressed.AddUFunction(Cursor, n"HandleClickPressed");
			OnClickReleased.AddUFunction(Cursor, n"HandleClickReleased");
		}

		PhoneGame.SceneCapture.TextureTarget = RenderTarget;

		OnClickPressed.AddUFunction(PhoneGame, n"HandleClickPressed");
		OnClickReleased.AddUFunction(PhoneGame, n"HandleClickReleased");

		PhoneGame.OnPhoneGameEnd.AddUFunction(this, n"HandlePhoneGameEnd");
		PhoneGame.OnPhoneGameRestart.AddUFunction(this, n"HandlePhoneGameRestart");
		PhoneGame.OnPhoneCall.AddUFunction(this, n"HandleCallPhone");

		CurrentGame = PhoneGame;
	}

	UFUNCTION()
	private void HandleCallPhone()
	{
		if (bPhoneCalled)
			return;

		bPhoneCalled = true;
		auto PhoneGame = SpawnActor(PhoneCall);
		SetPhoneGame(PhoneGame);
	}

	UFUNCTION()
	private void HandlePhoneGameRestart()
	{
		PhoneGameIndex--;
		NextPhoneGame();
	}

	UFUNCTION()
	private void HandlePhoneGameEnd()
	{
		NextPhoneGame();
	}
};