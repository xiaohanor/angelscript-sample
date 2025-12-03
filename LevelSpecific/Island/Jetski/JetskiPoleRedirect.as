enum EJetskiPoleRedirectDirection
{
	Both,
	Left,
	Right,
};

UCLASS(NotBlueprintable)
class AJetskiPoleRedirect : AHazeActor
{
	default ActorHiddenInGame = true;

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Collider;
	default Collider.BoxExtent = FVector(150, 150, 1000);
	default Collider.CollisionProfileName = n"InvisibleWall";
	default Collider.bGenerateOverlapEvents = false;
	default Collider.Mobility = EComponentMobility::Static;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.WorldScale3D = FVector(5);
#endif

	UPROPERTY(EditInstanceOnly)
	FVector BoxExtent = FVector(20, 150, 1000);

	UPROPERTY(EditInstanceOnly)
	EJetskiPoleRedirectDirection RedirectDirection;

	UPROPERTY(EditInstanceOnly, Meta = (ClampMin = "0.0"))
	float SafetyMargin = 20;

	UPROPERTY(EditInstanceOnly)
	bool bKillAtCenter = true;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bKillAtCenter", ClampMin = "0.0"))
	float CenterMargin = 50;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Collider.SetBoxExtent(BoxExtent, false);

		CenterMargin = Math::Min(CenterMargin, BoxExtent.Y);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collider.SetBoxExtent(BoxExtent, false);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		const float ArrowLength = 500;
		const float ArrowSize = 500;
		const float ArrowThickness = 5;

		const FLinearColor ForwardColor = FLinearColor::Red;
		const FLinearColor LeftColor = FLinearColor::Blue;
		const FLinearColor RightColor = FLinearColor::Green;

		FVector ImpactLocation = ActorLocation - ActorForwardVector * BoxExtent.X;

		const FVector Offset = ActorRightVector * CenterMargin;
		FVector LeftStart = ImpactLocation;
		FVector RightStart = ImpactLocation;

		bool bDrawLeft = false;
		bool bDrawRight = false;

		switch(RedirectDirection)
		{
			case EJetskiPoleRedirectDirection::Both:
				bDrawLeft = true;
				bDrawRight = true;
				break;

			case EJetskiPoleRedirectDirection::Left:
				bDrawLeft = true;
				break;

			case EJetskiPoleRedirectDirection::Right:
				bDrawRight = true;
				break;
		}

		if(bKillAtCenter)
		{
			if(bDrawLeft)
				LeftStart -= Offset;

			if(bDrawRight)
				RightStart += Offset;
		}

		if(bDrawLeft)
		{
			Debug::DrawDebugDirectionArrow(LeftStart, -ActorRightVector, ArrowLength, ArrowSize, LeftColor, ArrowThickness);
			Debug::DrawDebugSphere(ImpactLocation - (ActorRightVector * (BoxExtent.Y + Jetski::Radius + SafetyMargin)), Jetski::Radius, 12, LeftColor);
		}

		if(bDrawRight)
		{
			Debug::DrawDebugDirectionArrow(RightStart, ActorRightVector, ArrowLength, ArrowSize, RightColor, ArrowThickness);
			Debug::DrawDebugSphere(ImpactLocation + (ActorRightVector * (BoxExtent.Y + Jetski::Radius + SafetyMargin)), Jetski::Radius, 12, RightColor);
		}

		if(bKillAtCenter)
		{
			Debug::DrawDebugLine(LeftStart, RightStart, FLinearColor::Red, 10);

			if(bDrawLeft)
				Debug::DrawDebugArrow(LeftStart + (ActorForwardVector * -ArrowLength), LeftStart, ArrowSize * 2, ForwardColor, ArrowThickness * 2);
			
			if(bDrawRight)
				Debug::DrawDebugArrow(RightStart + (ActorForwardVector * -ArrowLength), RightStart, ArrowSize * 2, ForwardColor, ArrowThickness * 2);
		}
		else
		{
			Debug::DrawDebugArrow(ImpactLocation + (ActorForwardVector * -ArrowLength), ImpactLocation, ArrowSize * 2, ForwardColor, ArrowThickness * 2);
		}
	}
#endif
};