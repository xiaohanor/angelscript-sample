UCLASS(Abstract)
class USandHandCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(NotEditable)
	USandHandPlayerComponent SandHandComponent;

	FHazeAcceleratedFloat AcceleratedOpacity;
	float LastOpaqueTimeStamp = -SandHand::CrosshairLifetime;

	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		SandHandComponent = USandHandPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		if (SandHandComponent == nullptr)
			return;

		/*if (SandHandComponent.IsSystemActive())
		{
			// Get target crosshair opacity
			float OpacityTarget = 0.0;
			if (SandHandComponent.IsSandHandCharging() || SandHandComponent.IsSandHandCharged())
			{
				LastOpaqueTimeStamp = Time::GameTimeSeconds;
				OpacityTarget = 1.0;
			}
			else if (Time::GameTimeSeconds - LastOpaqueTimeStamp < FireMagic::UI::CrosshairLifetime)
			{
				OpacityTarget = 1.0;
			}

			// Lerp opacity
			float AccelerationTime = OpacityTarget == 1.0 ? FireMagic::UI::CrosshairBlendInTime : FireMagic::UI::CrosshairBlendOutTime;
			AcceleratedOpacity.AccelerateTo(OpacityTarget, AccelerationTime, Time::GetActorDeltaSeconds(Player));
		}
		else
		{
			AcceleratedOpacity.SnapTo(0.0);
		}

		SetRenderOpacity(AcceleratedOpacity.Value);*/
	}
}