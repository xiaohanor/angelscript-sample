class ASkylineDivingCar : AHazeActor
{

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent Pivot;

    UPROPERTY(DefaultComponent, Attach = Pivot)
    USceneComponent CarRoot;

    UPROPERTY(EditAnywhere)
    // float RotationSpeed = 1.2;
    float RotationSpeed = 2.5;

    UPROPERTY(EditAnywhere)
    float MoveSpeed = 17000.0;

    UPROPERTY(EditAnywhere)
    float TopSpeed = 17000.0;

    UPROPERTY(EditAnywhere)
    float Acceleration = 1000.0;

    UPROPERTY(EditAnywhere)
    float AccelerationTimer = 1.0;

    float AccelerationInitTimer;

    UPROPERTY(EditAnywhere)
    EHazePlayer Pilot = EHazePlayer::Zoe;

    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeCameraComponent Camera;

    FVector2D Input;

    UPROPERTY(DefaultComponent)
    UHazeCapabilityComponent CapabilityComponent;
    default CapabilityComponent.DefaultCapabilities.Add(n"SkylineDivingCarTurnCapability");

    float DesiredAngle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        auto Player = Game::GetPlayer(Pilot);
        Player.BlockCapabilities(CapabilityTags::Movement, this);
        Player.ActivateCamera(Camera, 0.0, this);
        Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
        AccelerationInitTimer = AccelerationTimer;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(AccelerationTimer <= 0 && MoveSpeed != TopSpeed)
        {
            AccelerationTimer = AccelerationInitTimer;

            if(MoveSpeed <= TopSpeed)
            {
                MoveSpeed = MoveSpeed + Acceleration;
            }
            else
            {
                MoveSpeed = TopSpeed;
            }

        }

        AccelerationTimer = AccelerationTimer - DeltaSeconds;

        FVector InputDirection = Root.WorldTransform.TransformVectorNoScale(FVector(Input.Y, Input.X, 0.0));
        FVector CurrentDirection = -Pivot.ForwardVector;
        float InputAngle = Math::RadiansToDegrees(Math::Atan2(-Input.X, -Input.Y));
        DesiredAngle = Math::LerpAngleDegrees(Pivot.RelativeRotation.Yaw, InputAngle, DeltaSeconds * RotationSpeed);

        // PrintToScreen();

        AddActorLocalOffset(-FVector::UpVector * MoveSpeed * DeltaSeconds);

        // Pivot.AddRelativeRotation(FRotator(0.0,Input.X * RotationSpeed * DeltaSeconds, 0.0));
        // Debug::DrawDebugLine(Pivot.WorldLocation, Pivot.WorldLocation + InputDirection  * 500.0);
        // Debug::DrawDebugLine(Pivot.WorldLocation, Pivot.WorldLocation + CurrentDirection  * 500.0);

        if (Input.X == 0) {
            // PrintToScreen("Not moving", 0.0);
        }

        Pivot.RelativeRotation = FRotator(0.0, DesiredAngle, 0.0);

    }

}