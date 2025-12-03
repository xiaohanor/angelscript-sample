UCLASS(Abstract)
class ADesertBreakPerchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchZoneComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	
	default MeshComp.bBlockVisualsOnDisable = false;

	bool bBreak = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bBreak)
		{
			PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartPerch");
			PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"EndPerch");
			PerchPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnInitiatedGrappleToPoint");
		}
	}

	UFUNCTION()
	private void OnInitiatedGrappleToPoint(AHazePlayerCharacter Player,
	                                       UGrapplePointBaseComponent GrapplePoint)
	{
		SetActorControlSide(Player);
	}

	UFUNCTION()
	private void StartPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchPointComp.DisableForPlayer(Player.GetOtherPlayer(), this);
		SetActorControlSide(Player);
		BreakPerchPoint(Player);
	}

	UFUNCTION()
	private void EndPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BreakPerchPoint(AHazePlayerCharacter Player)
	{
		//BP stuff :)
	}
};