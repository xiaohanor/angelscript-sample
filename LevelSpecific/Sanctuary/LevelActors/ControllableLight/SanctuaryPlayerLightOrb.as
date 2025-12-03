class ASanctuaryPlayerLightOrb : AHazeActor
{

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent Pivot;

    UPROPERTY(DefaultComponent, Attach = Pivot)
    USceneComponent LightRoot;

    UPROPERTY(EditAnywhere)
    float Speed = 600.0;

    UPROPERTY(EditAnywhere)
    EHazePlayer Pilot = EHazePlayer::Mio;

    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeCameraComponent Camera;

    FVector2D Input;

    UPROPERTY(DefaultComponent)
    UHazeCapabilityComponent CapabilityComponent;
    default CapabilityComponent.DefaultCapabilities.Add(n"SanctuaryPlayerLightOrbCapability");

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;


    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if (bAutoPlay)
		{
			auto Player = Game::GetPlayer(Pilot);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			Player.ActivateCamera(Camera, 0.0, this);
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::Instant);
		}
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {

		AddActorLocalOffset(FVector::ForwardVector * Input.Y * Speed * DeltaSeconds);
		AddActorLocalOffset(FVector::RightVector * Input.X * Speed * DeltaSeconds);

        if (Input.X == 0) {
            // PrintToScreen("" + Input.Y + " " + Input.X, 0.0);
        }

    }

}