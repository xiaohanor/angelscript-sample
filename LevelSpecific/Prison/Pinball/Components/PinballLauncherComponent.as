event void FPinballLauncherOnHitByBall(UPinballBallComponent BallComp, bool bIsProxy);

struct FPinballLauncherLerpBackSettings
{
	UPROPERTY(EditAnywhere)
	bool bLerpBack = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLerpBack", EditConditionHides))
	bool bOnlyLerpBackHorizontally = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLerpBack", EditConditionHides))
	bool bBaseDurationOnPing = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLerpBack && bBaseDurationOnPing", EditConditionHides))
	float LerpBackPingMultiplier = 1;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLerpBack && !bBaseDurationOnPing", EditConditionHides))
	float LerpBackDuration = 0.5;

	float GetLerpBackDuration() const
	{
		check(bLerpBack);

		if(bBaseDurationOnPing)
			return Network::PingOneWaySeconds * LerpBackPingMultiplier;
		else
			return LerpBackDuration;
	}
}

UCLASS(NotBlueprintable, NotPlaceable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class UPinballLauncherComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Launcher")
	FPinballLauncherLerpBackSettings LocalLerpBackSettings;

	UPROPERTY(EditAnywhere, Category = "Launcher")
	FPinballLauncherLerpBackSettings NetworkBallSideLerpBackSettings;

	UPROPERTY(EditAnywhere, Category = "Launcher")
	FPinballLauncherLerpBackSettings NetworkPaddleSideLerpBackSettings;

	UPROPERTY(EditAnywhere, Category = "Launcher")
	bool bAllowLaunchFromBallSide = false;

	/**
	 * Normally we stop being launched when moving down, but some launchers might want to override this,
	 * for example bounce pads aiming down into other bounce pads
	 */
	UPROPERTY(EditAnywhere, Category = "Launcher|Launched")
	bool bStayLaunchedWhenMovingDown = false;

	/**
	 * After this amount of time has passed, stop the launch
	 */
	UPROPERTY(EditAnywhere, Category = "Launcher|Launched")
	float MaxLaunchDuration = 0.3;

	UPROPERTY()
	FPinballLauncherOnHitByBall OnHitByBall;

	bool ShouldLerpBack() const
	{
		return GetLerpBackSettings().bLerpBack;
	}

	const FPinballLauncherLerpBackSettings& GetLerpBackSettings() const
	{
		if(Network::IsGameNetworked())
		{
			if(Pinball::GetBallPlayer().HasControl())
				return NetworkBallSideLerpBackSettings;
			else
				return NetworkPaddleSideLerpBackSettings;
		}
		else
		{
			return LocalLerpBackSettings;
		}
	}

	void BroadcastOnHitByBall(UPinballBallComponent BallComp, bool bIsProxy)
	{
		OnHitByBall.Broadcast(BallComp, bIsProxy);
	}
};