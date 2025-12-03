UCLASS(Abstract)
class UPlayerAdultAcidDragonTargetableWidget : UTargetableWidget
{
	UPROPERTY(Meta = (BindWidget))
	UImage CrosshairImage;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		CrosshairImage.SetColorAndOpacity(PlayerColor::Mio);
		CrosshairImage.SetRenderScale(FVector2D(3, 3));
	}

	void OnTakenFromPool() override
	{
		Super::OnTakenFromPool();
	}

	// UFUNCTION(BlueprintOverride)
	// void Tick(FGeometry MyGeometry, float InDeltaTime)
	// {
	// 	FVector CameraLocation = Player.GetViewLocation();
	// 	float Distance = CameraLocation.Distance(WidgetWorldPosition);
	// 	Print(f"{Distance=}");
	// 	float Scale = WidgetScale / Distance;
	// 	CrosshairImage.SetRenderScale(FVector2D(Scale, Scale));
	// }
}