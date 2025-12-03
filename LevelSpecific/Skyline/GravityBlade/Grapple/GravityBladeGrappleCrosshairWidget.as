UCLASS(Abstract)
class UGravityBladeGrappleCrosshairWidget : UCrosshairWidget
{
	UGravityBladeGrappleUserComponent GrappleComp;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
	}
}