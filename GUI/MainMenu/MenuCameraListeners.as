class AMenuCameraListeners : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAudioListenerComponent ListenerA;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAudioListenerComponent ListenerB;

	private TArray<UHazeAudioListenerComponent> Listeners;
	private AMainMenu MainMenu = nullptr;
	private AMenuCameraUser Camera = nullptr;

	private FVector PreviousPosition;

	UPROPERTY(EditInstanceOnly)
	float TeleportDistance = 30000;

	UPROPERTY(EditInstanceOnly)
	float MovementSpeed = 10000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Listeners.Add(ListenerA);
		Listeners.Add(ListenerB);

		MainMenu = TListedActors<AMainMenu>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Camera = MainMenu.CameraUser;
		if (Camera == nullptr)
			return;
		
		auto NewPosition = Camera.ActiveCamera.WorldLocation;

		if (PreviousPosition != NewPosition)
		{
			auto Distance = NewPosition.Distance(PreviousPosition);
			if (Distance >= TeleportDistance)
				PreviousPosition = NewPosition;
			else
			{
				PreviousPosition = PreviousPosition.MoveTowards(NewPosition, MovementSpeed * DeltaTime);
			}

			for (auto Listener: Listeners)
			{
				Listener.WorldTransform = Camera.ActiveCamera.WorldTransform;
				Listener.WorldLocation = PreviousPosition;

				Listener.GetReverbComponent().SetReverbFlags(EHazeAudioReverbFlag::QueueProcessing);
			}
		}

		#if TEST
		if (AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Gameplay))
		{
			Debug::DrawDebugPoint(PreviousPosition, 50, FLinearColor::Green);
			Debug::DrawDebugString(PreviousPosition, "Listeners & Reverb");
		}
		#endif

	}
}