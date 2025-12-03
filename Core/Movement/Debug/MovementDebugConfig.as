#if EDITOR
UCLASS(Config = EditorPerProjectUserSettings)
class UMovementDebugConfig
{
	UPROPERTY(Config)
	bool bEnableRerun = false;
};

namespace UMovementDebugConfig
{
	UMovementDebugConfig Get()
	{
		return Cast<UMovementDebugConfig>(UMovementDebugConfig.DefaultObject);
	}
};
#endif