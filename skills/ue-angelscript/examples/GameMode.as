// Example: Game Mode with round management, scoring, and player spawning
class AMyGameMode : AGameModeBase
{
    UPROPERTY(Category = "Game Rules")
    int32 ScoreToWin = 10;
    
    UPROPERTY(Category = "Game Rules")
    float RoundTime = 300.0f;
    
    UPROPERTY(Replicated)
    float CurrentRoundTime = 0.0f;
    
    UPROPERTY(Replicated)
    bool bGameInProgress = false;
    
    UPROPERTY()
    TArray<FVector> SpawnPoints;
    
    UPROPERTY()
    TMap<APlayerController, int32> PlayerScores;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        CollectSpawnPoints();
    }
    
    UFUNCTION()
    void CollectSpawnPoints()
    {
        TArray<AActor> FoundActors;
        GetAllActorsOfClass(ASpawnPoint::StaticClass(), FoundActors);
        
        for (AActor Actor : FoundActors)
        {
            SpawnPoints.Add(Actor.GetActorLocation());
        }
    }
    
    UFUNCTION(BlueprintOverride)
    void PostLogin(APlayerController NewPlayer)
    {
        Super::PostLogin(NewPlayer);
        
        PlayerScores.Add(NewPlayer, 0);
        
        if (!bGameInProgress && PlayerScores.Num() >= 2)
        {
            StartGame();
        }
    }
    
    UFUNCTION()
    void StartGame()
    {
        bGameInProgress = true;
        CurrentRoundTime = RoundTime;
        
        // Spawn all players
        for (APlayerController PC : PlayerScores.GetKeys())
        {
            RestartPlayer(PC);
        }
        
        // Start round timer
        GetWorld().GetTimerManager().SetTimer(
            RoundTimerHandle, 
            this, 
            n"UpdateRoundTime", 
            1.0f, 
            true
        );
        
        OnGameStarted.Broadcast();
    }
    
    UFUNCTION()
    void UpdateRoundTime()
    {
        CurrentRoundTime -= 1.0f;
        
        if (CurrentRoundTime <= 0)
        {
            EndRound();
        }
    }
    
    UFUNCTION(BlueprintOverride)
    void RestartPlayer(APlayerController NewPlayer)
    {
        FVector SpawnLocation = GetRandomSpawnLocation();
        FTransform SpawnTransform = FTransform(FRotator::ZeroRotator, SpawnLocation);
        
        APawn NewPawn = SpawnPlayerPawn(NewPlayer, SpawnTransform);
        if (NewPawn != nullptr)
        {
            NewPlayer.Possess(NewPawn);
        }
    }
    
    UFUNCTION()
    FVector GetRandomSpawnLocation()
    {
        if (SpawnPoints.Num() == 0)
            return FVector::ZeroVector;
            
        int32 Index = FMath::RandRange(0, SpawnPoints.Num() - 1);
        return SpawnPoints[Index];
    }
    
    UFUNCTION()
    void AddScore(APlayerController Player, int32 Points)
    {
        if (!PlayerScores.Contains(Player))
            return;
            
        int32 NewScore = PlayerScores[Player] + Points;
        PlayerScores[Player] = NewScore;
        
        OnScoreChanged.Broadcast(Player, NewScore);
        
        if (NewScore >= ScoreToWin)
        {
            EndGame(Player);
        }
    }
    
    UFUNCTION()
    void EndRound()
    {
        GetWorld().GetTimerManager().ClearTimer(RoundTimerHandle);
        
        // Determine winner based on score
        APlayerController Winner = nullptr;
        int32 HighestScore = 0;
        
        for (auto& Pair : PlayerScores)
        {
            if (Pair.Value > HighestScore)
            {
                HighestScore = Pair.Value;
                Winner = Pair.Key;
            }
        }
        
        if (Winner != nullptr && HighestScore >= ScoreToWin)
        {
            EndGame(Winner);
        }
        else
        {
            // Start new round
            CurrentRoundTime = RoundTime;
            for (APlayerController PC : PlayerScores.GetKeys())
            {
                RestartPlayer(PC);
            }
        }
    }
    
    UFUNCTION()
    void EndGame(APlayerController Winner)
    {
        bGameInProgress = false;
        GetWorld().GetTimerManager().ClearTimer(RoundTimerHandle);
        
        OnGameEnded.Broadcast(Winner);
    }
    
    // Delegates
delegate void FOnGameStarted();
delegate void FOnScoreChanged(APlayerController Player, int32 NewScore);
delegate void FOnGameEnded(APlayerController Winner);
    
    FOnGameStarted OnGameStarted;
    FOnScoreChanged OnScoreChanged;
    FOnGameEnded OnGameEnded;
    
    private FTimerHandle RoundTimerHandle;
}

// Spawn point marker
class ASpawnPoint : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    
    UPROPERTY(DefaultComponent, Attach = Root)
    UBillboardComponent Sprite;
    
    UPROPERTY()
    int32 TeamID = 0;
}
