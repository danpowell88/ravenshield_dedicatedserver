package main

import (
	"flag"
	"fmt"
	"log"
	"time"

	beacon "github.com/willroberts/openrvs-beacon"
)

var (
	ip   string
	port int
)

func init() {
	flag.StringVar(&ip, "ip", "127.0.0.1", "IP address of RS3 server")
	flag.IntVar(&port, "port", 7776, "Beacon port of RS3 server (usually game port + 1000)")
	flag.Parse()
}

func main() {
	reportBytes, err := beacon.GetServerReport(ip, port, 5*time.Second)
	if err != nil {
		log.Fatal("failed to read from server:", err)
	}
	report, err := beacon.ParseServerReport(ip, reportBytes)
	if err != nil {
		log.Fatal("failed to parse report:", err)
	}
	printReport(report)
}

func printReport(r *beacon.ServerReport) {
	fmt.Println("Server:", r.ServerName)
	fmt.Printf("Address: %s:%d\n", r.IPAddress, r.Port)
	fmt.Println("Game Version:", r.GameVersion)
	fmt.Println("Mod Name:", r.ModName)
	fmt.Println("MOTD:", r.MOTD)
	fmt.Println("Current Map:", r.CurrentMap)
	fmt.Println("Current Game Mode:", r.CurrentMode)
	if r.NumTerrorists > 0 {
		fmt.Println("Number of Terrorists:", r.NumTerrorists)
	}
	fmt.Println("Friendly Fire:", r.FriendlyFire)
	fmt.Printf("Active Players: %d out of %d\n", r.NumPlayers, r.MaxPlayers)
	for i := 0; i < len(r.ConnectedPlayerNames); i++ {
		fmt.Printf("- %s (Kills: %d, Ping: %dms)\n",
			r.ConnectedPlayerNames[i],
			r.ConnectedPlayerKills[i],
			r.ConnectedPlayerLatencies[i])
	}
}