class AIceFractalMovementPlane : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Mesh;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        AHazePlayerCharacter Player = Game::Zoe;
	    FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility, n"IceFractalMovementPlane");
        Trace.UseSphereShape(Player.CapsuleComponent.CapsuleRadius);
        Trace.IgnorePlayers();
        Trace.IgnoreActor(this);
        Trace.DebugDrawOneFrame();

        const FVector Start = (Player.ActorLocation + (FVector::UpVector * Player.CapsuleComponent.GetScaledCapsuleHalfHeight() * 2.0));
        const FVector End = Player.ActorLocation - (FVector::UpVector * 10000.0);

        FHitResult Hit = Trace.QueryTraceSingle(Start, End);
        if(Hit.bBlockingHit)
        {
            FVector NewLocation = ActorLocation;
            NewLocation.Z = Hit.Location.Z + 1.0;
            SetActorLocation(NewLocation);
        }
    }
}