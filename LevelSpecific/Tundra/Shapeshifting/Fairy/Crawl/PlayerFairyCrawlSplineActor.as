event void FTundraFairyCrawlSplineEnterExitEvent();

class ATundraPlayerFairyCrawlSplineActor : ASplineActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent EnterTrigger;
	default EnterTrigger.RelativeScale3D = FVector(0.3);
	default EnterTrigger.ShapeColor = FLinearColor::Green;
	default EnterTrigger.EditorLineThickness = 3.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent ExitTrigger;
	default ExitTrigger.RelativeLocation = FVector(0.0, 100.0, 0.0);
	default ExitTrigger.RelativeScale3D = FVector(0.3);
	default ExitTrigger.ShapeColor = FLinearColor::Red;
	default ExitTrigger.EditorLineThickness = 3.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BlockingVolume;
	default BlockingVolume.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY()
	FTundraFairyCrawlSplineEnterExitEvent OnEnterCrawl;

	UPROPERTY()
	FTundraFairyCrawlSplineEnterExitEvent OnExitCrawl;

	UPROPERTY(EditAnywhere)
	bool bIsOneWay = true;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraToActivate;

	UTundraPlayerFairyCrawlComponent CrawlComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		EnterTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterEnterTrigger");
		ExitTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterExitTrigger");

		CrawlComp = UTundraPlayerFairyCrawlComponent::GetOrCreate(Game::Zoe);
		MoveComp = UHazeMovementComponent::Get(Game::Zoe);
	}

	UFUNCTION()
	private void OnEnterEnterTrigger(AHazePlayerCharacter Player)
	{
		if(IsActorDisabled())
			return;

		if(Player.IsMio())
			return;

		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
		if(!ShapeshiftingComp.IsSmallShape())
			return;

		EnterOrExitCrawl(Player, false);
	}

	UFUNCTION()
	private void OnEnterExitTrigger(AHazePlayerCharacter Player)
	{
		if(IsActorDisabled())
			return;

		if(Player.IsMio())
			return;

		auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
		if(!ShapeshiftingComp.IsSmallShape())
			return;

		if(bIsOneWay && CrawlComp.CurrentCrawlSplineActor == nullptr)
			return;

		EnterOrExitCrawl(Player, true);
	}

	void EnterOrExitCrawl(AHazePlayerCharacter Player, bool bCalledFromExitTrigger)
	{
		if(CrawlComp.CurrentCrawlSplineActor != nullptr)
		{
			ExitCrawl();
		}
		else if(Player.ActorVelocity.DotProduct(GetInitialSplinePosition(bCalledFromExitTrigger).WorldRotation.ForwardVector) >= 0.0)
		{
			EnterCrawl(bCalledFromExitTrigger);
		}
	}

	void EnterCrawl(bool bReversed)
	{
		if(!HasControl())
			return;

		CrumbEnterCrawl(bReversed);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEnterCrawl(bool bReversed)
	{
		CrawlComp.CurrentCrawlSplineActor = this;
		CrawlComp.bReversed = bReversed;
		MoveComp.AddMovementIgnoresComponent(this, BlockingVolume);
	}

	void ExitCrawl()
	{
		if(!HasControl())
			return;

		CrumbExitCrawl();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExitCrawl()
	{
		CrawlComp.PreviousCrawlSplineActor = this;
		CrawlComp.CurrentCrawlSplineActor = nullptr;
		MoveComp.RemoveMovementIgnoresComponents(this);
	}

	FSplinePosition GetInitialSplinePosition(bool bReversed)
	{
		return Spline.GetSplinePositionAtSplineDistance(bReversed ? Spline.SplineLength : 0.0, !bReversed);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		ExitCrawl();
	}
}