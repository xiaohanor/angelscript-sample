struct FBombTossPlatformPositionValues
{
	UPROPERTY()
	FRotator BaseRailingRootRot;
	UPROPERTY()
	FVector BaseRailingRootLoc;
	UPROPERTY()
	FRotator RailingRootRot;
	UPROPERTY()
	FRotator PlatformMeshRootRot;

	bool opEquals(FBombTossPlatformPositionValues Other) const
	{
		return BaseRailingRootRot.Equals(Other.BaseRailingRootRot) && BaseRailingRootLoc.Equals(Other.BaseRailingRootLoc) && RailingRootRot.Equals(Other.RailingRootRot) && PlatformMeshRootRot.Equals(Other.PlatformMeshRootRot);
	}

}

enum EBombTossPlatformPosition
{
	WallUp,
	WallRight,
	WallDown,
	WallLeft,
	TiltUp,
	TiltRight,
	TiltDown,
	TiltLeft,
	FullTiltUp,
	FullTiltRight,
	FullTiltDown,
	FullTiltLeft,
	Neutral,
	Hidden,
	InvertedWallUp,
	InvertedWallRight,
	InvertedWallDown,
	InvertedWallLeft,
	DoubleWallUp,
	DoubleWallRight,
	DoubleWallDown,
	DoubleWallLeft,
	TripleWallUp,
	TripleWallRight,
	TripleWallDown,
	TripleWallLeft,
	Raised,
	HalfRaised,
	TiltUpRaised,
	TiltRightRaised,
	TiltDownRaised,
	TiltLeftRaised,
	MAX
}

UENUM()
enum EBombTossPlatformLightFormation
{
	All = 0b1111,
	None = 0b0000,
	Front = 0b0001,
	Right = 0b0010,
	Back = 0b0100,
	Left = 0b1000,
	FrontRight = 0b0011,
	RightBack = 0b0110,
	BackLeft = 0b1100,
	LeftFront = 0b1001,
	FrontBack = 0b0101,
	RightLeft = 0b1010,
}

enum EBombTossPlatformLightColor
{
	None,
	Green,
	Red,
	White,
	Num UMETA(Hidden)
}

enum EBombTossPlatformLightPlacement
{
	Front,
	Right,
	Back,
	Left,
}

struct FGameShowArenaPlatformMoveData
{
	FGameShowArenaPlatformMoveData(EBombTossPlatformPosition InPosition, float InMoveDuration = 0, float InMoveDelay = 0)
	{
		Position = InPosition;
		MoveDuration = InMoveDuration;
		MoveDelay = InMoveDelay;
	}
	UPROPERTY()
	EBombTossPlatformPosition Position;
	UPROPERTY()
	float MoveDuration = 0;
	UPROPERTY()
	float MoveDelay = 0;
	UPROPERTY()
	bool bShouldGlitch;
	UPROPERTY()
	bool bRotateBeforeExtending = false;
}

struct FBombTossPlatformPositionLayouts
{
	UPROPERTY()
	TMap<FGuid, FGameShowArenaPlatformMoveData> ArmMoveDataByGuid;
}

struct FBombTossPlatformLightPlacementData
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EBombTossPlatformLightFormation Formation;
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EBombTossPlatformLightColor Color;

	FBombTossPlatformLightPlacementData(EBombTossPlatformLightFormation InFormation, EBombTossPlatformLightColor InColor)
	{
		Formation = InFormation;
		Color = InColor;
	}
}

struct FBombTossPlatformLightFormationLayouts
{
	UPROPERTY()
	TMap<FGuid, FBombTossPlatformLightPlacementData> LightDataByGuid;

	void MapGuidAndLightPlacementData(FGuid Guid, FBombTossPlatformLightPlacementData LightPlacementData)
	{
		LightDataByGuid.Add(Guid, LightPlacementData);
	}
}

struct FBombTossPlatformPatternSection
{
	UPROPERTY()
	EBombTossPlatformPosition Position;

	UPROPERTY()
	FBombTossPlatformLightPlacementData StartLightData;

	UPROPERTY()
	FBombTossPlatformLightPlacementData EndLightData;

	UPROPERTY()
	float Duration;

	UPROPERTY()
	float StartDelay;

	UPROPERTY()
	float EndDelay;

	UPROPERTY()
	TArray<FGuid> PlatformGuids;

	void StoreGuids(FGuid Guid)
	{
		PlatformGuids.Add(Guid);
	}
}

struct FBombTossPlatformPattern
{
	UPROPERTY()
	TArray<FBombTossPlatformPatternSection> PatternSections;
}