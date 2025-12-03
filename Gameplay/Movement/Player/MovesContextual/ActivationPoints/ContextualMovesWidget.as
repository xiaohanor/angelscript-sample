
UCLASS(Abstract)
class UContextualMovesWidget : UTargetableWidget
{
	/* If true the widget should appear as normal, if false it should be grayed out or similar */
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsInteractive = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float DistanceScaleFactor = 1.0;

	UPROPERTY(BlueprintReadWrite, Interp)
	float TriangleSpacingAmount = 0.0;

	UPROPERTY(BindWidget)
	UWidget OffscreenArrow;

	UPROPERTY(BindWidget)
	UImage Triangle_Upper;
	UPROPERTY(BindWidget)
	UImage Triangle_Right;
	UPROPERTY(BindWidget)
	UImage Triangle_Bottom;
	UPROPERTY(BindWidget)
	UImage Triangle_Left;

	UPROPERTY(BindWidget)
	UImage Frame_Top;
	UPROPERTY(BindWidget)
	UImage Frame_Right;
	UPROPERTY(BindWidget)
	UImage Frame_Bottom;
	UPROPERTY(BindWidget)
	UImage Frame_Left;

	UPlayerContextualMovesTargetingComponent TargetingComp;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		UpdateTriangleSpacing();
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TargetingComp = UPlayerContextualMovesTargetingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		Triangle_Bottom.SetRenderTransform(FWidgetTransform());
		Triangle_Upper.SetRenderTransform(FWidgetTransform());
		Triangle_Right.SetRenderTransform(FWidgetTransform());
		Triangle_Left.SetRenderTransform(FWidgetTransform());

		Frame_Bottom.SetRenderTransform(FWidgetTransform());
		Frame_Top.SetRenderTransform(FWidgetTransform());
		Frame_Right.SetRenderTransform(FWidgetTransform());
		Frame_Left.SetRenderTransform(FWidgetTransform());
	}

	UFUNCTION()
	void PlayAuraAnimationIfNotCooldown(UWidgetAnimation Animation, float Cooldown = 2.0)
	{
		if (TargetingComp.AuraAnimationCooldownUntil < Time::RealTimeSeconds)
		{
			PlayAnimation(Animation);
			TargetingComp.AuraAnimationCooldownUntil = Time::RealTimeSeconds + Cooldown;
		}
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetWidgetPlayerColor()
	{
		if (Player == nullptr || Player.IsMio())
			return PlayerColor::Mio;
		else
			return PlayerColor::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UpdateDirectionArrow(InDeltaTime);
		UpdateTriangleSpacing();
	}

	UFUNCTION(BlueprintOverride)
	void BP_OnActivationAnimation()
	{
		Super::BP_OnActivationAnimation();
		TargetingComp.AuraAnimationCooldownUntil = Time::RealTimeSeconds + 1.0;
	}

	void UpdateDirectionArrow(float DeltaTime)
	{
		if (bIsOnEdgeOfScreen)
		{
			OffscreenArrow.RenderOpacity = Math::FInterpConstantTo(
				OffscreenArrow.RenderOpacity, 1.0, DeltaTime, 5.0
			);

			float Angle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.0).HeadingAngle();
			OffscreenArrow.SetRenderTransformAngle(Math::RadiansToDegrees(Angle));
		}
		else
		{
			OffscreenArrow.RenderOpacity = Math::FInterpConstantTo(
				OffscreenArrow.RenderOpacity, 0.0, DeltaTime, 5.0
			);
		}
	}

	void ApplyTriangleSpacing(UImage Image)
	{
		FWidgetTransform Transform = Image.RenderTransform;
		Transform.Translation.X = 0;
		Transform.Translation.Y = -14.0 * TriangleSpacingAmount * DistanceScaleFactor;
		Image.SetRenderTransform(Transform);
	}

	void UpdateTriangleSpacing()
	{
		ApplyTriangleSpacing(Triangle_Upper);
		ApplyTriangleSpacing(Frame_Top);
		ApplyTriangleSpacing(Triangle_Bottom);
		ApplyTriangleSpacing(Frame_Bottom);
		ApplyTriangleSpacing(Triangle_Left);
		ApplyTriangleSpacing(Frame_Left);
		ApplyTriangleSpacing(Triangle_Right);
		ApplyTriangleSpacing(Frame_Right);
	}
}