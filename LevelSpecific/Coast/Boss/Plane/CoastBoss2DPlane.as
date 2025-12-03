asset CoastBossPlaneSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UCoastBoss2DPlaneMovementCapability);
	Capabilities.Add(UCoastBoss2DPlaneSizeCapability);
}

class ACoastBoss2DPlane : AHazeActor
{
	access AccessCapability = private, UCoastBoss2DPlaneMovementCapability, UAnimInstanceCoastBoss;

	UPROPERTY(EditInstanceOnly)
	access : AccessCapability ASplineActor MoveSpline;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(CoastBossPlaneSheet);

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent VelocityComp;

	// -----------------------

	const float MaxWidthRatio = 16.0 / 9.0;
	const float MinWidthRatio = 4.0 / 3.0;

	const float PlaneHeight = 2500.0;
	FVector2D DefaultPlaneRatio = FVector2D(MaxWidthRatio, 1.0);
	FVector2D PlaneExtents = DefaultPlaneRatio * PlaneHeight * 0.5;
	float PlayersSmallestRatio = MaxWidthRatio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CoastBossDevToggles::CoastBoss.MakeVisible();
		CoastBossDevToggles::AutoShoot.MakeVisible();
		CoastBossDevToggles::Draw::Draw2DPlane.MakeVisible();
		CoastBossDevToggles::Draw::DrawDebugPlayers.MakeVisible();
		CoastBossDevToggles::Draw::DrawDebugTrain.MakeVisible();
		CoastBossDevToggles::Draw::DrawDebugBoss.MakeVisible();

		if (Network::IsGameNetworked() && Game::Zoe.HasControl())
		{
			UHazeCameraComponent Camera = Game::Zoe.GetCurrentlyUsedCamera();
			CrumbSendPlayerRatio(Camera.AspectRatio);
		}
		if (Game::Mio.HasControl())
		{
			UHazeCameraComponent Camera = Game::Mio.GetCurrentlyUsedCamera();
			CrumbSendPlayerRatio(Camera.AspectRatio);
		}
	}

	float GetPlaneHeightRatio() const
	{
		return PlaneExtents.Y / PlaneExtents.X;
	}

	FVector ProjectOnPlane(FVector Location)
	{
		FVector Relative = Location - ActorLocation;
		float ProjectionDist = ActorForwardVector.DotProduct(Relative);
		return Location + Relative * ProjectionDist;
	}

	FRotator GetPlayerHeadingRotation()
	{
		return FRotator::MakeFromXZ(ActorRightVector, ActorUpVector);
	}

	FVector GetDirectionInWorld(FVector2D DirectionOnPlane)
	{
		return (ActorUpVector * DirectionOnPlane.Y) + (ActorRightVector * DirectionOnPlane.X);
	}

	FVector GetLocationInWorld(FVector2D LocationOnPlane)
	{
		return ActorLocation + (ActorUpVector * LocationOnPlane.Y) + (ActorRightVector * LocationOnPlane.X);
	}

	FVector2D GetLocationOnPlane(FVector WorldLocationOnPlane)
	{
		FVector RelativeLocation = WorldLocationOnPlane - ActorLocation;
		float Forwards = ActorRightVector.DotProduct(RelativeLocation);
		float Upwards = ActorUpVector.DotProduct(RelativeLocation);
		return FVector2D(Forwards, Upwards);
	}

	FVector2D GetDirectionOnPlane(FVector WorldDirectionOnPlane)
	{
		float Forwards = ActorRightVector.DotProduct(WorldDirectionOnPlane);
		float Upwards = ActorUpVector.DotProduct(WorldDirectionOnPlane);
		return FVector2D(Forwards, Upwards);
	}

	FVector GetLocationSnappedToPlane(FVector WorldLocationOnPlane)
	{
		FVector RelativeLocation = WorldLocationOnPlane - ActorLocation;
		float Forwards = ActorRightVector.DotProduct(RelativeLocation);
		float Upwards = ActorUpVector.DotProduct(RelativeLocation);
		return ActorLocation + (ActorRightVector * Forwards) + (ActorUpVector * Upwards);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSendPlayerRatio(float AspectRatio)
	{
		if (AspectRatio < PlayersSmallestRatio)
			PlayersSmallestRatio = Math::Clamp(AspectRatio, MinWidthRatio, MaxWidthRatio);
	}

	bool IsOutsideOfPlaneX(FVector2D RelativeLocation)
	{
		float LargerPlane = PlaneExtents.X * 1.2;
		if (RelativeLocation.X < -LargerPlane)
			return true;
		if (RelativeLocation.X > LargerPlane)
			return true;
		return false;
	}

	bool IsOutsideOfPlaneY(FVector2D RelativeLocation)
	{
		float LargerPlane = PlaneExtents.Y * 1.2;
		if (RelativeLocation.Y < -LargerPlane)
			return true;
		if (RelativeLocation.Y > LargerPlane)
			return true;
		return false;
	}
};