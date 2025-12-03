UCLASS(Abstract)
class AKiteTownRubberbandingManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor RaceSplineActor;
	UHazeSplineComponent RaceSplineComp;

	UPROPERTY()
	TSubclassOf<UKiteTownTrackWidget> TrackWidgetClass;

	AHazePlayerCharacter LosingPlayer = nullptr;
	float DistanceDifference = 0.0;

	bool bRubberBandingEnabled = true;

	bool bShowProgressTracker = false;
	UKiteTownTrackWidget TrackWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RaceSplineComp = RaceSplineActor.Spline;

		DevTogglesKiteTown::RubberBanding.MakeVisible();
		LosingPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DevTogglesKiteTown::RubberBanding.IsEnabled())
		{
			DistanceDifference = 0.0;
			return;
		}

		float MioDistAlongSpline = RaceSplineComp.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation);
		float ZoeDistAlongSpline = RaceSplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation);

		if (MioDistAlongSpline > ZoeDistAlongSpline)
		{
			LosingPlayer = Game::Zoe;
			DistanceDifference = Math::Max(MioDistAlongSpline - ZoeDistAlongSpline, 0.0);
		}
		else
		{
			LosingPlayer = Game::Mio;
			DistanceDifference = Math::Max(ZoeDistAlongSpline - MioDistAlongSpline, 0.0);
		}
	}

	bool IsPlayerLosing(AHazePlayerCharacter Player)
	{
		if (Player.IsMio() && LosingPlayer.IsMio())
			return true;
		if (Player.IsZoe() && LosingPlayer.IsZoe())
			return true;

		return false;
	}

	AHazePlayerCharacter GetLeadingPlayer()
	{
		return LosingPlayer.OtherPlayer;
	}

	float GetDistanceDifference() const
	{
		return DistanceDifference;
	}

	float GetPlayerProgress(AHazePlayerCharacter Player)
	{
		return RaceSplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation)/RaceSplineComp.SplineLength;
	}
}

namespace KiteTown
{
	AKiteTownRubberbandingManager GetRubberBandingManager()
	{
		return TListedActors<AKiteTownRubberbandingManager>().GetSingle();
	}
}