
enum EGravityBikeFreeBoostApplyMode
{
	/**
	 * Boost is applied as an acceleration on top of regular movement
	 */
	Acceleration,

	/**
	 * Boost simply applies some settings (higher max speed)
	 */
	Settings,
};

enum EGravityBikeFreeBoostChargeMode
{
    TurnAmount,
    Timed,
};

/**
 * Settings applied on GravityBikeFree when boosting
 */
asset GravityBikeFreeSettingsBoost of UGravityBikeFreeSettings
{
	MaxSpeed = 6000; // 6000
	Acceleration = 20000; // 30000
};

class UGravityBikeFreeBoostSettings : UHazeComposableSettings
{
	UPROPERTY()
	EGravityBikeFreeBoostApplyMode ApplyMode = EGravityBikeFreeBoostApplyMode::Settings;

	UPROPERTY()
    EGravityBikeFreeBoostChargeMode BoostChargeMode = EGravityBikeFreeBoostChargeMode::Timed;

	UPROPERTY()
    float MaxBoostTime = 2.0;

	UPROPERTY()
    float BoostAcceleration = 20000;

	UPROPERTY()
	float BoostScale = 1.0;

	/**
	 * Timed Boost
	 */
	UPROPERTY()
    float BoostChargeDuration = 0.2;

	/**
	 * FOV
	 */
	UPROPERTY()
    float BoostFOVAdditive = 10;
};