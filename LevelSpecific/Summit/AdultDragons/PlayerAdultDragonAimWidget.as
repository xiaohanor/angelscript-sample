UCLASS(Abstract)
class APlayerAdultDragonAimWidget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WidgetViewRoot;

	UPROPERTY(DefaultComponent, Attach = WidgetViewRoot)	
	UWidgetComponent NearWidget;
	default NearWidget.RelativeLocation = FVector(0,0,0);

	UPROPERTY(DefaultComponent, Attach = WidgetViewRoot)	
	UWidgetComponent FarWidget;
	default FarWidget.RelativeLocation = FVector(100,0,0);

	private AHazePlayerCharacter PlayerOwner;
	private FVector NearOriginalRelativeLocation;
	private FVector FarOriginalRelativeLocation;
	
	private FAimingResult AimTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		NearOriginalRelativeLocation = NearWidget.RelativeLocation;
		FarOriginalRelativeLocation = FarWidget.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FRotator ViewRotation = PlayerOwner.GetViewRotation();
		FRotator TargetRotation = AimTarget.AimDirection.Rotation();

		if(AimTarget.AutoAimTarget != nullptr && AimTarget.AimDirection.DotProduct(ViewRotation.ForwardVector) > 0.2)
		{
			TargetRotation = Math::RInterpTo(WidgetViewRoot.WorldRotation, TargetRotation, DeltaSeconds, 10);
			WidgetViewRoot.WorldRotation = TargetRotation;
		}
		else
		{
			TargetRotation = Math::RInterpTo(WidgetViewRoot.RelativeRotation, FRotator::ZeroRotator, DeltaSeconds, 10);
			WidgetViewRoot.RelativeRotation = TargetRotation;
		}

		NearWidget.RelativeLocation = NearOriginalRelativeLocation;
		FarWidget.RelativeLocation = FarOriginalRelativeLocation;
		
	}

	void SetAimDirection(FAimingResult AimResult)
	{
		AimTarget = AimResult;
	}

	void SetPlayerOwner(AHazePlayerCharacter Player)
	{
		PlayerOwner = Player;

		NearWidget.SetRenderedForPlayer(Player, false);
		FarWidget.SetRenderedForPlayer(Player, false);

		NearWidget.SetRenderedForPlayer(Player.OtherPlayer, false);
		FarWidget.SetRenderedForPlayer(Player.OtherPlayer, false);
	}
};


UCLASS(Abstract)
class UPlayerAdultDragonAimWidgetIcon : UHazeUserWidget
{

};

