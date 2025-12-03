UCLASS(Config = LevelFlow, DefaultConfig, Meta = (DisplayName = "Level Flow"))
class ULevelFlowSettings : UDeveloperSettings
{
	UPROPERTY(Config, EditAnywhere, Meta = (TitleProperty = "SectionName"))
	TArray<FLevelFlowSection> Sections;
}

struct FLevelFlowLevel
{
	UPROPERTY()
	FString PersistentPath;
};

struct FLevelFlowSection
{
	UPROPERTY()
	FString SectionName;
	UPROPERTY()
	TArray<FLevelFlowLevel> Levels;
}